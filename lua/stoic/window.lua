local format = require("stoic.format")
local bookmarks = require("stoic.bookmarks")

local util = require("stoic.util")
local set_opt = vim.api.nvim_set_option_value
local W = {}

-- Window state
local win = nil
local buf = nil
local current_entry = nil
local highlight_ns = vim.api.nvim_create_namespace("stoic_highlights")

local function handle_info(message)
	vim.notify("Stoic: " .. message, vim.log.levels.INFO)
end

-- Generate footer text based on keymaps
local function footer_text(keymaps_config)
	local keymaps = keymaps_config or {}
	return string.format(
		"[%s] next | [%s] prev | [%s] bookmark | [B] bookmarks | [%s] quit",
		keymaps.next or "n",
		keymaps.prev or "p",
		keymaps.bookmark or "b",
		keymaps.quit or "q"
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
		title = "🌃 stoic.nvim",
		footer = footer_text(entry_config.keymaps),
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
		buftype = "nofile",
		filetype = "markdown",
		bufhidden = "wipe",
	}

	for opt, val in pairs(buffer_opts) do
		set_opt(opt, val, { buf = buf })
	end

	-- Create window (enter = true to focus immediately)
	local win_id = vim.api.nvim_open_win(buf, true, window_config)

	-- Set window options efficiently
	local window_opts = {
		wrap = true,
		linebreak = true,
		number = false,
		relativenumber = false,
		cursorline = false,
	}

	for opt, val in pairs(window_opts) do
		set_opt(opt, val, { win = win_id })
	end

	return { buf = buf, win = win_id }
end

-- Close window and clean up resources
local function close()
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
	if not win or not win.buf then
		return
	end

	local keymaps = entry_config.keymaps or {}
	local opts = { buffer = win.buf, silent = true, nowait = true, desc = "Stoic navigation" }

	-- Use a single keymap setup loop to reduce function calls
	local keymap_actions = {
		[keymaps.next or "n"] = function()
			vim.cmd("StoicNext")
		end,
		[keymaps.prev or "p"] = function()
			vim.cmd("StoicPrev")
		end,
		[keymaps.bookmark or "b"] = function()
			vim.cmd("StoicBookmark")
		end,
		[keymaps.quit or "q"] = function()
			close()
		end,
		["B"] = function()
			vim.cmd("StoicBookmarks")
		end,
	}

	for key, action in pairs(keymap_actions) do
		vim.keymap.set("n", key, action, opts)
	end
end

-- Show entry in window
local function show_entry_in_window(entry, entry_config)
	if not entry then
		return
	end

	current_entry = entry

	-- Close existing window if open
	close()

	-- Create new window
	win = create_window(entry_config)
	if not win then
		util.error("window creation", "Failed to create window")
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
		vim.o.shortmess = original_shortmess .. "W"

		-- Set buffer as modifiable before writing
		set_opt("modifiable", true, { buf = win.buf })
		set_opt("readonly", false, { buf = win.buf })
		vim.api.nvim_buf_set_lines(win.buf, 0, -1, false, content)
		set_opt("modifiable", true, { buf = win.buf })
		set_opt("readonly", true, { buf = win.buf })

		-- Restore original options
		vim.o.eventignore = original_eventignore
		vim.o.shortmess = original_shortmess

		-- Apply highlights efficiently using extmarks
		for _, hl in ipairs(highlights) do
			local line_length = #vim.api.nvim_buf_get_lines(win.buf, hl.line, hl.line + 1, false)[1] or 0
			local end_col = math.min(hl.col_end, line_length)
			if hl.col_start <= line_length then
				vim.api.nvim_buf_set_extmark(win.buf, highlight_ns, hl.line, hl.col_start, {
					end_col = end_col,
					hl_group = hl.group,
				})
			end
		end

		-- Set up keymaps
		setup_keymaps(entry_config)
	end
end

-- Refresh entry display without closing window
local function refresh_entry_display(entry, entry_config)
	if not entry or not win or not win.buf then
		return
	end

	current_entry = entry

	-- Format content
	local content, highlights = format.format_entry(entry, entry_config)

	-- Suppress W10 warning by temporarily disabling readonly notification
	local original_eventignore = vim.o.eventignore
	local original_shortmess = vim.o.shortmess
	vim.o.eventignore = "BufModifiedSet"
	vim.o.shortmess = original_shortmess .. "W"

	-- Set buffer as modifiable before writing
	set_opt("modifiable", true, { buf = win.buf })
	set_opt("readonly", false, { buf = win.buf })
	vim.api.nvim_buf_set_lines(win.buf, 0, -1, false, content)
	set_opt("modifiable", true, { buf = win.buf })
	set_opt("readonly", true, { buf = win.buf })

	-- Restore original options
	vim.o.eventignore = original_eventignore
	vim.o.shortmess = original_shortmess

	-- Clear existing highlights and apply new ones using extmarks
	vim.api.nvim_buf_clear_namespace(win.buf, highlight_ns, 0, -1)
	for _, hl in ipairs(highlights) do
		local line_length = #vim.api.nvim_buf_get_lines(win.buf, hl.line, hl.line + 1, false)[1] or 0
		local end_col = math.min(hl.col_end, line_length)
		if hl.col_start <= line_length then
			vim.api.nvim_buf_set_extmark(win.buf, highlight_ns, hl.line, hl.col_start, {
				end_col = end_col,
				hl_group = hl.group,
			})
		end
	end
end

-- Public API functions
function W.show_entry(entry, entry_config)
	show_entry_in_window(entry, entry_config)
end

function W.show_next(entry_config)
	if not current_entry then
		util.error("navigation", "No current entry available for next navigation")
		return
	end

	local data = require("stoic.data")
	-- Ensure we have a valid index, fallback to current entry's index or find it
	local idx = current_entry._index
	if not idx then
		-- Find the index by searching through all data
		local all_data = data.get_all_data()
		for i, entry in ipairs(all_data) do
			if entry.docId == current_entry.docId then
				idx = i
				break
			end
		end

		-- If still not found, try to find by date as fallback
		if not idx and current_entry.date then
			for i, entry in ipairs(all_data) do
				if entry.date == current_entry.date then
					idx = i
					break
				end
			end
		end

		-- If still not found, start from first entry
		if not idx then
			util.error("navigation", "Current entry not found in data, starting from first entry")
			idx = 1
		end
	end

	local next_entry = data.get_next_data(idx)
	if next_entry then
		show_entry_in_window(next_entry, entry_config)
	else
		util.error("navigation", "Failed to get next entry")
	end
end

function W.show_prev(entry_config)
	if not current_entry then
		util.error("navigation", "No current entry available for previous navigation")
		return
	end

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

		-- If still not found, try to find by date as fallback
		if not current_idx and current_entry.date then
			for i, entry in ipairs(all_data) do
				if entry.date == current_entry.date then
					current_idx = i
					break
				end
			end
		end

		-- If still not found, start from last entry
		if not current_idx then
			util.error("navigation", "Current entry not found in data, starting from last entry")
			current_idx = #all_data
		end
	end

	local prev_entry = data.get_prev_data(current_idx)
	if prev_entry then
		show_entry_in_window(prev_entry, entry_config)
	else
		util.error("navigation", "Failed to get previous entry")
	end
end

function W.toggle_bookmark(entry_config)
	if not current_entry then
		return
	end

	local entry_is_bookmarked = bookmarks.is_bookmarked(current_entry.docId)

	if entry_is_bookmarked then
		bookmarks.rm(current_entry.docId)
	-- Notification removed - user can see bookmark indicator in UI
	else
		bookmarks.add(current_entry)
		-- Notification removed - user can see bookmark indicator in UI
	end

	-- Refresh display without closing window
	refresh_entry_display(current_entry, entry_config)
end

function W.show_bookmarks(entry_config)
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

	local success, _ = pcall(function()
		vim.ui.select(items, {
			prompt = "Select bookmarked entry:",
			format_item = function(item)
				return item
			end,
		}, function(choice, idx)
			if choice and idx then
				-- Get the full entry using docId to ensure quote and commentary are included
				local data = require("stoic.data")
				local full_entry = data.get_data_by_docId(bookmarked[idx].docId)
				if full_entry then
					show_entry_in_window(full_entry, entry_config)
				else
					util.error(
						"bookmark navigation",
						"Full entry not found for docId: " .. (bookmarked[idx].docId or "nil")
					)
				end
			end
		end)
	end)

	-- If vim.ui.select fails, use a simple input-based fallback
	if not success then
		-- Show list of bookmarks and ask for number input
		local bookmark_list = "Bookmarks:\n"
		for i, entry in ipairs(bookmarked) do
			bookmark_list = bookmark_list .. string.format("%d. %s - %s\n", i, entry.title, entry.date)
		end

		-- Create a simple buffer to show bookmarks
		local fallback_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(fallback_buf, 0, -1, false, vim.split(bookmark_list, "\n"))
		set_opt("modifiable", false, { buf = fallback_buf })
		set_opt("readonly", true, { buf = fallback_buf })

		-- Create a simple window
		local win_config = {
			title = "Bookmarks (enter number to jump, q to quit)",
			style = "minimal",
			relative = "editor",
			border = "rounded",
			width = 80,
			height = math.min(#bookmarked + 5, 20),
			row = math.floor((vim.api.nvim_list_uis()[1].height - math.min(#bookmarked + 5, 20)) / 2),
			col = math.floor((vim.api.nvim_list_uis()[1].width - 80) / 2),
		}

		local fallback_win = vim.api.nvim_open_win(fallback_buf, true, win_config)

		-- Set up keymaps for the fallback window
		vim.keymap.set("n", "q", function()
			if vim.api.nvim_win_is_valid(fallback_win) then
				vim.api.nvim_win_close(fallback_win, true)
			end
			if vim.api.nvim_buf_is_valid(fallback_buf) then
				vim.api.nvim_buf_delete(fallback_buf, { force = true })
			end
		end, { buffer = fallback_buf, silent = true })

		-- Allow number selection
		vim.keymap.set("n", "<CR>", function()
			local line = vim.api.nvim_get_current_line()
			local num = line:match("^(%d+)")
			if num then
				local idx = tonumber(num)
				if idx >= 1 and idx <= #bookmarked then
					local data = require("stoic.data")
					local full_entry = data.get_data_by_docId(bookmarked[idx].docId)
					if full_entry then
						show_entry_in_window(full_entry, entry_config)
					else
						util.error(
							"bookmark navigation",
							"Full entry not found for docId: " .. (bookmarked[idx].docId or "nil")
						)
					end
				end
			end

			-- Close the fallback window
			if vim.api.nvim_win_is_valid(fallback_win) then
				vim.api.nvim_win_close(fallback_win, true)
			end
			if vim.api.nvim_buf_is_valid(fallback_buf) then
				vim.api.nvim_buf_delete(fallback_buf, { force = true })
			end
		end, { buffer = fallback_buf, silent = true })
	end
end

function W.close_window()
	close()
end

function W.get_current_entry()
	return current_entry
end

function W.is_window_open()
	return win ~= nil
end

return W
