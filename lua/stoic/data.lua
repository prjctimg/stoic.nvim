local M = {}

-- Data state (lazy loading)
local stoic_data = {}
local data_by_date = {}
local data_by_docId = {}
local month_order = {
  January = 1, February = 2, March = 3, April = 4, May = 5, June = 6,
  July = 7, August = 8, September = 9, October = 10, November = 11, December = 12
}

-- Cache for frequently accessed data
local data_loaded = false
local data_file_path = nil

-- Error handling
local function handle_error(operation, error_msg)
  local msg = string.format("Stoic: Error during %s: %s", operation, error_msg or "unknown error")
  vim.notify(msg, vim.log.levels.ERROR)
end

local function handle_info(message)
  vim.notify("Stoic: " .. message, vim.log.levels.INFO)
end

-- Parse date string and return components
local function parse_date(date_str)
  if not date_str then return nil end
  local month, day = date_str:match("(%a+)%s+(%d+)")
  if not month or not day then return nil end
  return { month = month, day = tonumber(day) }
end

-- Create date index for sorting
local function create_date_index(date_str)
  if not date_str then return 0 end
  local date_parts = parse_date(date_str)
  if not date_parts then return 0 end
  local month_num = month_order[date_parts.month]
  if not month_num then return 0 end
  return (month_num * 100) + date_parts.day
end

-- Get data file path (cached)
local function get_data_file_path()
  if data_file_path then return data_file_path end
  data_file_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h") .. "/stoic.json"
  return data_file_path
end

-- Load data from JSON file (lazy loading)
local function load_data()
  if data_loaded then return true end

  local file = get_data_file_path()
  if not vim.fn.filereadable(file) then
    handle_error("data loading", "Data file not found at " .. file)
    return false
  end

  local content = vim.fn.readfile(file)
  if not content or #content == 0 then
    handle_error("data loading", "Empty data file")
    return false
  end

  local success, parsed_data = pcall(vim.json.decode, table.concat(content, "\n"))
  if not success then
    handle_error("data loading", "Failed to parse data file - " .. parsed_data)
    return false
  end

  stoic_data = parsed_data

  -- Pre-compute indexes for fast lookup
  data_by_date = {}
  data_by_docId = {}

  for i, entry in ipairs(stoic_data) do
    local date_idx = create_date_index(entry.date)
    entry._date_idx = date_idx
    entry._index = i

    if entry.date then
      data_by_date[entry.date] = entry
    end

    if entry.docId then
      data_by_docId[entry.docId] = entry
    end
  end

  -- Sort data by date index for chronological navigation
  table.sort(stoic_data, function(a, b)
    return a._date_idx < b._date_idx
  end)

  data_loaded = true
  handle_info("Loaded " .. #stoic_data .. " entries")
  return true
end

-- Public API functions
function M.get_all_data()
  if not data_loaded then
    load_data()
  end
  return stoic_data
end

function M.get_data_by_date(date_str)
  if not data_loaded then
    load_data()
  end
  return data_by_date[date_str]
end

function M.get_data_by_index(idx)
  if not data_loaded then
    load_data()
  end
  local entry = stoic_data[idx]
  if entry then
    entry._index = idx
  end
  return entry
end

function M.get_data_by_docId(docId)
  if not data_loaded then
    load_data()
  end
  return data_by_docId[docId]
end

function M.get_next_data(current_idx)
  if not data_loaded then
    load_data()
  end
  if not current_idx then return M.get_data_by_index(1) end

  local next_idx = (current_idx % #stoic_data) + 1
  return M.get_data_by_index(next_idx)
end

function M.get_prev_data(current_idx)
  if not data_loaded then
    load_data()
  end
  if not current_idx then return M.get_data_by_index(#stoic_data) end

  local prev_idx = current_idx - 1
  if prev_idx < 1 then prev_idx = #stoic_data end
  return M.get_data_by_index(prev_idx)
end

function M.create_date_index(date_str)
  return create_date_index(date_str)
end

function M.parse_date(date_str)
  return parse_date(date_str)
end

function M.is_data_loaded()
  return data_loaded
end

-- Force reload data (useful for testing)
function M.reload_data()
  data_loaded = false
  data_by_date = {}
  data_by_docId = {}
  return load_data()
end

return M