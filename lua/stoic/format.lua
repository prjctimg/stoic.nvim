local bookmarks = require("stoic.bookmarks")

local M = {}

-- Cache for text wrapping results
local wrap_cache = {}
local max_cache_size = 100



-- Clear wrapping cache
local function clear_wrap_cache()
  wrap_cache = {}
end

-- Manage cache size
local function manage_cache_size()
  if #wrap_cache > max_cache_size then
    -- Remove oldest entries (simple FIFO)
    for i = 1, #wrap_cache - max_cache_size do
      table.remove(wrap_cache, 1)
    end
  end
end

-- Wrap text with caching
local function wrap_text(text, width)
  if not text then return {} end

  -- Create cache key
  local cache_key = text .. "|" .. width
  if wrap_cache[cache_key] then
    return wrap_cache[cache_key]
  end

  local lines = {}

  -- Split text into paragraphs by literal line breaks
  local paragraphs = {}
  for paragraph in text:gmatch("([^\n]+)") do
    table.insert(paragraphs, paragraph)
  end

  for _, paragraph in ipairs(paragraphs) do
    -- Use vim.split to properly handle word boundaries
    local words = vim.split(paragraph, "%s+", { trimempty = true })
    local current_line = ""

    for _, word in ipairs(words) do
      if #current_line == 0 then
        current_line = word
      elseif #current_line + 1 + #word <= width then
        current_line = current_line .. " " .. word
      else
        table.insert(lines, current_line)
        current_line = word
      end
    end

    -- Add last line if there's content
    if #current_line > 0 then
      table.insert(lines, current_line)
    end

    -- Add blank line between paragraphs (except for the last one)
    if #paragraphs > 1 then
      table.insert(lines, "")
    end
  end

  -- Cache the result
  manage_cache_size()
  wrap_cache[cache_key] = lines
  return lines
end

-- Format entry content and highlights
function M.format_entry(entry, entry_config)
  if not entry then return {}, {} end

  local content = {}
  local highlights = {}
  local line_num = 0

  -- Window width for text wrapping
  local window_width = (entry_config.window and entry_config.window.width) or 80
  local text_width = window_width - 4 -- Account for padding

  -- Add date at the top with emoji
  if entry.date then
    table.insert(content, "")
    local date_line = "📅 " .. entry.date
    table.insert(content, date_line)
    table.insert(highlights, {
      group = entry_config.highlights.author,
      line = line_num + 2,
      col_start = 0,
      col_end = #date_line
    })
    table.insert(content, "")
    line_num = line_num + 3
  end

  -- Add title with emoji
  if entry.title then
    table.insert(content, "")
    local title_line = "🎯 " .. entry.title
    table.insert(content, title_line)
    table.insert(highlights, {
      group = entry_config.highlights.title,
      line = line_num + 2,
      col_start = 0,
      col_end = #title_line
    })
    table.insert(content, "")
    line_num = line_num + 3
  end

  -- Add quote with emoji
  if entry.quote then
    table.insert(content, "")
    local quote_header = "💭 Quote:"
    table.insert(content, quote_header)
    table.insert(highlights, {
      group = entry_config.highlights.title,
      line = line_num + 2,
      col_start = 0,
      col_end = #quote_header
    })
    line_num = line_num + 1

    local quote_lines = wrap_text(entry.quote, text_width)
    for i, line in ipairs(quote_lines) do
      table.insert(content, "  " .. line)
      table.insert(highlights, {
        group = entry_config.highlights.quote,
        line = line_num + i,
        col_start = 0,
        col_end = #line + 2
      })
    end
    table.insert(content, "")
    line_num = line_num + #quote_lines + 2
  end

  -- Add author and book with emoji
  if entry.author or entry.book then
    local author_book = "📚 "
    if entry.author then
      author_book = author_book .. entry.author
    end
    if entry.book then
      author_book = author_book .. " - " .. entry.book
    end
    table.insert(content, author_book)
    table.insert(highlights, {
      group = entry_config.highlights.author,
      line = line_num + 1,
      col_start = 0,
      col_end = #author_book
    })
    table.insert(content, "")
    line_num = line_num + 2
  end

  -- Add commentary section with emoji
  if entry.commentary and entry.commentary ~= "" then
    table.insert(content, "")
    local commentary_header = "💡 Commentary:"
    table.insert(content, commentary_header)
    table.insert(highlights, {
      group = entry_config.highlights.title,
      line = line_num + 2,
      col_start = 0,
      col_end = #commentary_header
    })
    line_num = line_num + 1

    -- Use simpler wrapping for commentary to avoid formatting issues
    local commentary_text = entry.commentary:gsub("\n", " ")
    local commentary_lines = wrap_text(commentary_text, text_width)
    for i, line in ipairs(commentary_lines) do
      table.insert(content, "  " .. line)
      table.insert(highlights, {
        group = entry_config.highlights.commentary,
        line = line_num + i,
        col_start = 0,
        col_end = #line + 2
      })
    end
    table.insert(content, "")
    line_num = line_num + #commentary_lines + 2
  end

  -- Add bookmark indicator only
  local is_entry_bookmarked = bookmarks.is_bookmarked(entry.docId)
  local bookmark_indicator = is_entry_bookmarked and "🔖 Bookmarked" or ""

  if bookmark_indicator ~= "" then
    table.insert(content, bookmark_indicator)
    table.insert(content, "")
  end

  return content, highlights
end

-- Clear format cache
function M.clear_cache()
  clear_wrap_cache()
end

return M