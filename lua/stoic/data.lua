local D = {}

local util = require("stoic.util")
-- Data state (lazy loading)
local data = {}
local by_date = {}
local by_docId = {}
local month_order = {
	January = 1,
	February = 2,
	March = 3,
	April = 4,
	May = 5,
	June = 6,
	July = 7,
	August = 8,
	September = 9,
	October = 10,
	November = 11,
	December = 12,
}

-- Cache for frequently accessed data
local loaded = false
local file_path = nil

local function handle_info(message)
	vim.notify("Stoic: " .. message, vim.log.levels.INFO)
end

-- Parse date string and return components
local function parse_date(date_str)
	if not date_str then
		return nil
	end
	local month, day = date_str:match("(%a+)%s+(%d+)[a-z]*")
	if not month or not day then
		return nil
	end
	return { month = month, day = tonumber(day) }
end

-- Create date index for sorting
local function create_date_index(date_str)
	if not date_str then
		return 0
	end
	local date_parts = parse_date(date_str)
	if not date_parts then
		return 0
	end
	local month_num = month_order[date_parts.month]
	if not month_num then
		return 0
	end
	return (month_num * 100) + date_parts.day
end

-- Get data file path (cached)
local function get_data_file_path()
	if file_path then
		return file_path
	end
	file_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h") .. "/stoic.json"
	return file_path
end

-- Load data from JSON file (lazy loading)
local function load_data()
	if loaded then
		return true
	end

	local file = get_data_file_path()
	if not vim.fn.filereadable(file) then
		util.error("data loading", "Data file not found at " .. file)
		return false
	end

	local content = vim.fn.readfile(file)
	if not content or #content == 0 then
		util.error("data loading", "Empty data file")
		return false
	end

	local success, parsed_data = pcall(vim.json.decode, table.concat(content, "\n"))
	if not success then
		util.error("data loading", "Failed to parse data file - " .. parsed_data)
		return false
	end

	data = parsed_data

	-- Pre-compute indexes for fast lookup
	by_date = {}
	by_docId = {}

	for i, entry in ipairs(data) do
		local date_idx = create_date_index(entry.date)
		entry._date_idx = date_idx
		entry._index = i

		-- Ensure required fields exist and are valid
		if not entry.docId then
			entry.docId = "entry_" .. i
			handle_info("Generated docId for entry at index " .. i)
		end

		if entry.date then
			by_date[entry.date] = entry
		end

		if entry.docId then
			by_docId[entry.docId] = entry
		end
	end

	-- Sort data by date index for chronological navigation
	table.sort(data, function(a, b)
		return a._date_idx < b._date_idx
	end)

	-- Update _index values after sorting to reflect actual array positions
	for i, entry in ipairs(data) do
		entry._index = i
	end

	loaded = true
	return true
end

-- Public API functions
function D.get_all_data()
	if not loaded then
		load_data()
	end
	return data
end

function D.get_data_by_date(date_str)
	if not loaded then
		load_data()
	end
	return by_date[date_str]
end

function D.get_data_by_index(idx)
	if not loaded then
		load_data()
	end
	local entry = data[idx]
	return entry
end

function D.get_data_by_docId(docId)
	if not loaded then
		load_data()
	end
	return by_docId[docId]
end

function D.get_next_data(current_idx)
	if not loaded then
		load_data()
	end
	if not current_idx then
		return D.get_data_by_index(1)
	end

	local next_idx = (current_idx % #data) + 1
	return D.get_data_by_index(next_idx)
end

function D.get_prev_data(current_idx)
	if not loaded then
		load_data()
	end
	if not current_idx then
		return D.get_data_by_index(#data)
	end

	local prev_idx = current_idx - 1
	if prev_idx < 1 then
		prev_idx = #data
	end
	return D.get_data_by_index(prev_idx)
end

function D.create_date_index(date_str)
	return create_date_index(date_str)
end

function D.parse_date(date_str)
	return parse_date(date_str)
end

function D.is_data_loaded()
	return loaded
end

-- Force reload data (useful for testing)
function D.reload_data()
	loaded = false
	by_date = {}
	by_docId = {}
	return load_data()
end

return D

