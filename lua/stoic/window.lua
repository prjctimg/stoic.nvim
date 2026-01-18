local format = require("stoic.format")
local bookmarks = require("stoic.bookmarks")

local M = {}

-- Window state
local win = nil
local buf = nil
local current_entry = nil



-- Error handling
local function handle_error(operation, error_msg)
  local msg = string.format("Stoic: Error during %s: %s", operation, error_msg or "unknown error")
  vim.notify(msg, vim.log.levels.ERROR)
end

local function handle_info(message)
  vim.notify("Stoic: " .. message, vim.log.levels.INFO)
end

-- Generate footer text based on keymaps
local function generate_footer_text(keymaps_config)
  local keymaps = keymaps_config or {}
  return string.format("[%s] next | [%s] prev | [%s] bookmark | [B] bookmarks | [%s] quit",
    keymaps.next or 'n',
    keymaps.prev or 'p',
    keymaps.bookmark or 'b',
    keymaps.quit or 'q'
  )
end

-- Create window with optimized configuration
local function create_window(entry_config)
  local user_config = entry_config.window or {}

  -- Calculate position based on user preference
  local width = user_config.width or 80
  local height = user_config.height or 30

  -- Default to centered position, fallback to top-left if no UI available
  local row, col = 0, 0
  local uis = vim.api.nvim_list_uis()
  if #uis > 0 then
    local screen_width = uis[1].width
    local screen_height = uis[1].height
    if user_config.position == "center" then
      row = math.floor((screen_height - height) / 2)
      col = math.floor((screen_width - width) / 2)
    end
  end

  -- Create valid window config
  local window_config = {
    title = "Stoic Wisdom",
    footer = generate_footer_text(entry_config.keymaps),
    footer_pos = "center",
    style = "minimal",
    relative = "editor",
    border = user_config.border or "rounded",
    width = width,
    height = height,
    row = row,
    col = col,
  }

  -- Create buffer
  buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options efficiently
  local buffer_opts = {
    modifiable = false,
    readonly = true,
    buftype = 'nofile',
    filetype = 'markdown',
    bufhidden = 'wipe'
  }

  for opt, val in pairs(buffer_opts) do
    vim.api.nvim_buf_set_option(buf, opt, val)
  end

  -- Create window (enter = true to focus immediately)
  local win_id = vim.api.nvim_open_win(buf, true, window_config)

  -- Set window options efficiently
  local window_opts = {
    wrap = true,
    linebreak = true,
    number = false,
    relativenumber = false,
    cursorline = false
  }

  for opt, val in pairs(window_opts) do
    vim.api.nvim_win_set_option(win_id, opt, val)
  end

  return { buf = buf, win = win_id }
end

-- Close window and clean up resources
local function close_window()
  if win then
    if win.win and vim.api.nvim_win_is_valid(win.win) then
      vim.api.nvim_win_close(win.win, true)
    end
    if win.buf and vim.api.nvim_buf_is_valid(win.buf) then
      vim.api.nvim_buf_delete(win.buf, { force = true })
    end
    win = nil
    buf = nil
  end
end

-- Setup keymaps with optimized options
local function setup_keymaps(entry_config)
  if not win or not win.buf then return end

  local keymaps = entry_config.keymaps or {}
  local opts = { buffer = win.buf, silent = true, nowait = true, desc = "Stoic navigation" }

  -- Use a single keymap setup loop to reduce function calls
  local keymap_actions = {
    [keymaps.next or 'n'] = function() M.show_next() end,
    [keymaps.prev or 'p'] = function() M.show_prev() end,
    [keymaps.bookmark or 'b'] = function() M.toggle_bookmark() end,
    [keymaps.quit or 'q'] = function() close_window() end,
    ['B'] = function() M.show_bookmarks() end
  }

  for key, action in pairs(keymap_actions) do
    vim.keymap.set('n', key, action, opts)
  end
end

-- Show entry in window
local function show_entry_in_window(entry, entry_config)
  if not entry then return end

  current_entry = entry

  -- Close existing window if open
  close_window()

  -- Create new window
  win = create_window(entry_config)
  if not win then
    handle_error("window creation", "Failed to create window")
    return
  end

  -- Format content
  local content, highlights = format.format_entry(entry, entry_config)

  -- Set buffer content efficiently
  if win.buf then
    -- Suppress W10 warning by temporarily disabling readonly notification
    local original_eventignore = vim.o.eventignore
    local original_shortmess = vim.o.shortmess
    vim.o.eventignore = "BufModifiedSet"
    vim.o.shortmess = vim.o.shortmess .. "W"  -- W to suppress "written to file" messages

    -- Set buffer as modifiable before writing
    vim.api.nvim_buf_set_option(win.buf, 'modifiable', true)
    vim.api.nvim_buf_set_option(win.buf, 'readonly', false)
    vim.api.nvim_buf_set_lines(win.buf, 0, -1, false, content)
    vim.api.nvim_buf_set_option(win.buf, 'modifiable', true)
    vim.api.nvim_buf_set_option(win.buf, 'readonly', true)

    -- Restore original options
    vim.o.eventignore = original_eventignore
    vim.o.shortmess = original_shortmess

    -- Apply highlights efficiently
    for _, hl in ipairs(highlights) do
      vim.api.nvim_buf_add_highlight(win.buf, 0, hl.group, hl.line, hl.col_start, hl.col_end)
    end

    -- Set up keymaps
    setup_keymaps(entry_config)
  end
end

-- Public API functions
function M.show_entry(entry, entry_config)
  show_entry_in_window(entry, entry_config)
end

function M.show_next(entry_config)
  if not current_entry then return end

  local data = require("stoic.data")
  -- Ensure we have a valid index, fallback to current entry's index or find it
  local current_idx = current_entry._index
  if not current_idx then
    -- Find the index by searching through all data
    local all_data = data.get_all_data()
    for i, entry in ipairs(all_data) do
      if entry.docId == current_entry.docId then
        current_idx = i
        break
      end
    end
  end
  
  local next_entry = data.get_next_data(current_idx)
  show_entry_in_window(next_entry, entry_config)
end

function M.show_prev(entry_config)
  if not current_entry then return end

  local data = require("stoic.data")
  -- Ensure we have a valid index, fallback to current entry's index or find it
  local current_idx = current_entry._index
  if not current_idx then
    -- Find the index by searching through all data
    local all_data = data.get_all_data()
    for i, entry in ipairs(all_data) do
      if entry.docId == current_entry.docId then
        current_idx = i
        break
      end
    end
  end
  
  local prev_entry = data.get_prev_data(current_idx)
  show_entry_in_window(prev_entry, entry_config)
end

function M.toggle_bookmark(entry_config)
  if not current_entry then return end

  local entry_is_bookmarked = bookmarks.is_bookmarked(current_entry.docId)

  if entry_is_bookmarked then
    bookmarks.remove_bookmark(current_entry.docId)
    handle_info("Bookmark removed")
  else
    bookmarks.add_bookmark(current_entry)
    handle_info("Bookmark added")
  end

  -- Refresh display
  show_entry_in_window(current_entry, entry_config)
end

function M.show_bookmarks(entry_config)
  local bookmarked = bookmarks.get_all_bookmarks()
  if #bookmarked == 0 then
    handle_info("No bookmarks found")
    return
  end

  -- Create a simple picker for bookmarks
  local items = {}
  for i, entry in ipairs(bookmarked) do
    table.insert(items, string.format("%d. %s - %s", i, entry.title, entry.date))
  end

  vim.ui.select(items, {
    prompt = "Select bookmarked entry:",
    format_item = function(item) return item end
  }, function(choice, idx)
    if choice and idx then
      -- Get the full entry using docId to ensure quote and commentary are included
      local data = require("stoic.data")
      local full_entry = data.get_data_by_docId(bookmarked[idx].docId)
      if full_entry then
        show_entry_in_window(full_entry, entry_config)
      else
        handle_error("bookmark navigation", "Full entry not found for docId: " .. (bookmarked[idx].docId or "nil"))
      end
    end
  end)
end

function M.close_window()
  close_window()
end

function M.get_current_entry()
  return current_entry
end

function M.is_window_open()
  return win ~= nil
end

return M