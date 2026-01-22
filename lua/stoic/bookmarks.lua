local B = {}

local bookmarks = {}
local loaded = false
local bookmarks_file = ""
local util = require("stoic.util")
local bookmarks_cache = {}

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
	if loaded then
		return true
	end

	local file = get_bookmarks_file()

	if vim.fn.filereadable(file) == 1 then
		local content = vim.fn.readfile(file)
		if content and #content > 0 then
			local success, data = pcall(vim.json.decode, table.concat(content, "\n"))
			if success then
				bookmarks = data or {}
				loaded = true
				return true
			else
				util.error("bookmarks loading", "Failed to parse bookmarks file")
			end
		end
	end

	bookmarks = {}
	loaded = true
	return true
end

-- Save bookmarks to JSON file
local function save_bookmarks()
	if not loaded then
		return false
	end

	local file = get_bookmarks_file()
	local content = vim.json.encode(bookmarks)

	local success = pcall(vim.fn.writefile, vim.split(content, "\n"), file)
	if not success then
		util.error("bookmarks saving", "Failed to save bookmarks")
		return false
	end

	-- Clear cache after saving
	bookmarks_cache = {}
	return true
end

-- Add bookmark
function B.add(entry)
	if not entry or not entry.docId then
		util.error("bookmark operation", "Cannot bookmark entry without docId")
		return false
	end

	if loaded == false then
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
		added_at = os.date("%Y-%m-%d %H:%M:%S"),
	}

	bookmarks[entry.docId] = bookmark

	-- Clear cache
	bookmarks_cache = {}

	if save_bookmarks() then
		vim.notify("Stoic: Entry added to bookmarks", vim.log.levels.INFO)
		return true
	end

	return false
end

-- Remove bookmark
function B.rm(docId)
	if not docId then
		util.error("bookmark operation", "Cannot remove bookmark without docId")
		return false
	end

	if loaded == false then
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
		vim.notify("Stoic: Entry removed from bookmarks", vim.log.levels.INFO)
		return true
	end

	return false
end

-- Check if entry is bookmarked
function B.is_bookmarked(docId)
	if not docId then
		return false
	end

	if loaded == false then
		load_bookmarks()
	end

	return bookmarks[docId] ~= nil
end

-- Get all bookmarks (cached)
function B.get_all_bookmarks()
	if loaded == false then
		load_bookmarks()
	end

	if #bookmarks_cache > 0 then
		return bookmarks_cache
	end

	local list = {}
	for _, bookmark in pairs(bookmarks) do
		table.insert(list, bookmark)
	end

	-- Sort by date (chronological order)
	local data = require("stoic.data")
	table.sort(list, function(a, b)
		local date_a = data.create_date_index(a.date)
		local date_b = data.create_date_index(b.date)
		return date_a < date_b
	end)

	-- Cache the result
	bookmarks_cache = list
	return list
end

-- Get bookmark by docId
function B.get_bookmark(docId)
	if loaded == false then
		load_bookmarks()
	end

	return bookmarks[docId]
end

-- Toggle bookmark for an entry
function B.toggle_bookmark(entry)
	if B.is_bookmarked(entry.docId) then
		return B.rm(entry.docId)
	else
		return B.add(entry)
	end
end

-- Clear bookmarks cache
function B.clear_cache()
	bookmarks_cache = {}
end

function B.is_bookmarks_loaded()
	return loaded
end

return B
