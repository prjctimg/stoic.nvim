local I = {}
local util = require("stoic.util")
-- === DEFAULT CONFIGURATION ===
local default_config = {
	daily_reading = false,
	window = {
		position = "center",
		width = 80,
		height = 30,
		border = "rounded",
	},
	keymaps = {
		next = "n",
		prev = "p",
		bookmark = "b",
		quit = "q",
	},
	highlights = {
		title = "StoicTitle",
		author = "StoicAuthor",
		quote = "StoicQuote",
		commentary = "StoicCommentary",
	},
}

-- === GLOBAL STATE ===
local config = {}
local setup_complete = false

-- Module imports (lazy loading)
local data, navigation, window, bookmarks, format

-- Lazy load modules
local function get_data()
	if not data then
		data = require("stoic.data")
	end
	return data
end

local function get_navigation()
	if not navigation then
		navigation = require("stoic.navigation")
	end
	return navigation
end

local function get_window()
	if not window then
		window = require("stoic.window")
	end
	return window
end

local function get_bookmarks()
	if not bookmarks then
		bookmarks = require("stoic.bookmarks")
	end
	return bookmarks
end

local function get_format()
	if not format then
		format = require("stoic.format")
	end
	return format
end

function I._handle_info(message)
	vim.notify("Stoic: " .. message, vim.log.levels.INFO)
end

function I._validate_config(user_config)
	if not user_config then
		return true
	end

	-- Basic validation
	if user_config.window and type(user_config.window) ~= "table" then
		util.error("config validation", "window config must be a table")
		return false
	end

	if user_config.keymaps and type(user_config.keymaps) ~= "table" then
		util.error("config validation", "keymaps config must be a table")
		return false
	end

	return true
end

-- === SETUP FUNCTION ===
function I.setup(opts)
	-- Prevent multiple setups
	if setup_complete then
		return true
	end

	-- Validate configuration
	if not I._validate_config(opts) then
		return false
	end

	config = vim.tbl_deep_extend("force", default_config, opts or {})

	-- Create highlight groups
	vim.api.nvim_set_hl(0, config.highlights.title, { fg = "#ffffff", bold = true })
	vim.api.nvim_set_hl(0, config.highlights.author, { fg = "#8888ff" })
	vim.api.nvim_set_hl(0, config.highlights.quote, { fg = "#ffff88" })
	vim.api.nvim_set_hl(0, config.highlights.commentary, { fg = "#cccccc" })

	-- Set up daily reading autocmd if enabled
	if config.daily_reading then
		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				I.show_today()
			end,
			once = true,
			desc = "Show daily stoic reading on Neovim launch",
		})
	end

	setup_complete = true
	return true
end

-- === HELPER FUNCTION ===
local function ensure_setup()
	if not setup_complete then
		I.setup()
	end
end

-- === PUBLIC API FUNCTIONS ===
function I.show_today()
	ensure_setup()
	local today_entry = get_navigation().get_today_entry()
	get_window().show_entry(today_entry, config)
end

function I.show_date(date_str)
	ensure_setup()
	local entry = get_navigation().get_date_entry(date_str)
	if entry then
		get_window().show_entry(entry, config)
	else
		vim.notify("Stoic: No entry found for date " .. date_str, vim.log.levels.ERROR)
	end
end

function I.show_next()
	ensure_setup()
	get_window().show_next(config)
end

function I.show_prev()
	ensure_setup()
	get_window().show_prev(config)
end

function I.toggle_bookmark()
	ensure_setup()
	get_window().toggle_bookmark(config)
end

function I.show_bookmarks()
	ensure_setup()
	get_window().show_bookmarks(config)
end

-- === COMMAND HANDLERS ===
function I.handle_stoic_command()
	I.show_today()
end

function I.handle_stoic_today_command()
	I.show_today()
end

function I.handle_stoic_date_command(opts)
	local date_str = opts.args
	if not date_str or date_str == "" then
		util.error("command execution", "please provide a date (e.g., :StoicDate Aug 16)")
		return
	end
	I.show_date(date_str)
end

function I.handle_stoic_next_command()
	I.show_next()
end

function I.handle_stoic_prev_command()
	I.show_prev()
end

function I.handle_stoic_bookmark_command()
	I.toggle_bookmark()
end

function I.handle_stoic_bookmarks_command()
	I.show_bookmarks()
end

function I._get_state()
	return {
		config = config,
		setup_complete = setup_complete,
		data_loaded = get_data().is_data_loaded(),
		bookmarks_loaded = get_bookmarks().is_bookmarks_loaded(),
		window_open = get_window().is_window_open(),
	}
end

function I.clear_cache()
	local format_module = get_format()
	local bookmarks_module = get_bookmarks()

	format_module.clear_cache()
	bookmarks_module.clear_cache()
	get_navigation().clear_today_cache()
end

function I.reload_data()
	return get_data().reload_data()
end

function I.reload_bookmarks()
	return get_bookmarks().reload_bookmarks()
end

-- Force reset setup (useful for testing)
function I._reset_setup()
	setup_complete = false
	config = {}
	data = nil
	navigation = nil
	window = nil
	bookmarks = nil
	format = nil
end

return I

