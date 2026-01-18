local M = {}

-- Bookmarks state (lazy loading)
local bookmarks = {}
local bookmarks_loaded = false
local bookmarks_file = ""

-- Cache for frequently accessed bookmarks
local bookmarks_cache = {}

-- Error handling
local function handle_error(operation, error_msg)
  local msg = string.format("Stoic: Error during %s: %s", operation, error_msg or "unknown error")
  vim.notify(msg, vim.log.levels.ERROR)
end

local function handle_info(message)
  vim.notify("Stoic: " .. message, vim.log.levels.INFO)
end

-- Get bookmarks file path (cached)
local function get_bookmarks_file()
  if bookmarks_file == "" then
    local config_dir = vim.fn.stdpath("data") .. "/stoic"
    if vim.fn.isdirectory(config_dir) == 0 then
      vim.fn.mkdir(config_dir, "p")
    end
    bookmarks_file = config_dir .. "/bookmarks.json"
  end
  return bookmarks_file
end

-- Load bookmarks from JSON file (lazy loading)
local function load_bookmarks()
  if bookmarks_loaded then return true end

  local file = get_bookmarks_file()

  if vim.fn.filereadable(file) == 1 then
    local content = vim.fn.readfile(file)
    if content and #content > 0 then
      local success, data = pcall(vim.json.decode, table.concat(content, "\n"))
      if success then
        bookmarks = data or {}
        bookmarks_loaded = true
        return true
      else
        handle_error("bookmarks loading", "Failed to parse bookmarks file")
      end
    end
  end

  bookmarks = {}
  bookmarks_loaded = true
  return true
end

-- Save bookmarks to JSON file
local function save_bookmarks()
  if not bookmarks_loaded then return false end

  local file = get_bookmarks_file()
  local content = vim.json.encode(bookmarks)

  local success = pcall(vim.fn.writefile, vim.split(content, "\n"), file)
  if not success then
    handle_error("bookmarks saving", "Failed to save bookmarks")
    return false
  end

  -- Clear cache after saving
  bookmarks_cache = {}
  return true
end

-- Add bookmark
function M.add_bookmark(entry)
  if not entry or not entry.docId then
    handle_error("bookmark operation", "Cannot bookmark entry without docId")
    return false
  end

  if bookmarks_loaded == false then
    load_bookmarks()
  end

  -- Check if already bookmarked
  if bookmarks[entry.docId] then
    vim.notify("Stoic: Entry already bookmarked", vim.log.levels.WARN)
    return false
  end

  -- Create bookmark entry
  local bookmark = {
    docId = entry.docId,
    title = entry.title,
    author = entry.author,
    date = entry.date,
    book = entry.book,
    added_at = os.date("%Y-%m-%d %H:%M:%S")
  }

  bookmarks[entry.docId] = bookmark

  -- Clear cache
  bookmarks_cache = {}

  if save_bookmarks() then
    handle_info("Bookmark added")
    return true
  end

  return false
end

-- Remove bookmark
function M.remove_bookmark(docId)
  if not docId then
    handle_error("bookmark operation", "Cannot remove bookmark without docId")
    return false
  end

  if bookmarks_loaded == false then
    load_bookmarks()
  end

  if not bookmarks[docId] then
    vim.notify("Stoic: Bookmark not found", vim.log.levels.WARN)
    return false
  end

  bookmarks[docId] = nil

  -- Clear cache
  bookmarks_cache = {}

  if save_bookmarks() then
    handle_info("Bookmark removed")
    return true
  end

  return false
end

-- Check if entry is bookmarked
function M.is_bookmarked(docId)
  if not docId then return false end

  if bookmarks_loaded == false then
    load_bookmarks()
  end

  return bookmarks[docId] ~= nil
end

-- Get all bookmarks (cached)
function M.get_all_bookmarks()
  if bookmarks_loaded == false then
    load_bookmarks()
  end

  -- Check cache first
  if #bookmarks_cache > 0 then
    return bookmarks_cache
  end

  local bookmark_list = {}
  for _, bookmark in pairs(bookmarks) do
    table.insert(bookmark_list, bookmark)
  end

  -- Sort by date (chronological order)
  local data = require("stoic.data")
  table.sort(bookmark_list, function(a, b)
    local date_a = data.create_date_index(a.date)
    local date_b = data.create_date_index(b.date)
    return date_a < date_b
  end)

  -- Cache the result
  bookmarks_cache = bookmark_list
  return bookmark_list
end

-- Get bookmark by docId
function M.get_bookmark(docId)
  if bookmarks_loaded == false then
    load_bookmarks()
  end

  return bookmarks[docId]
end

-- Toggle bookmark for an entry
function M.toggle_bookmark(entry)
  if not entry or not entry.docId then
    handle_error("bookmark operation", "Cannot toggle bookmark for entry without docId")
    return false
  end

  if M.is_bookmarked(entry.docId) then
    return M.remove_bookmark(entry.docId)
  else
    return M.add_bookmark(entry)
  end
end

-- Clear bookmarks cache
function M.clear_cache()
  bookmarks_cache = {}
end

-- Force reload bookmarks
function M.reload_bookmarks()
  bookmarks_loaded = false
  bookmarks = {}
  bookmarks_cache = {}
  return load_bookmarks()
end

function M.is_bookmarks_loaded()
  return bookmarks_loaded
end

return M