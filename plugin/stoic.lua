-- Plugin registration for stoic.nvim
-- Optimized command registration with reduced startup overhead

-- Centralized command registry to reduce duplication
local commands = {
	Stoic = {
		handler = "handle_stoic_command",
		desc = "Show today's stoic reading",
	},
	StoicToday = {
		handler = "handle_stoic_today_command",
		desc = "Show today's stoic reading",
	},
	StoicDate = {
		handler = "handle_stoic_date_command",
		nargs = 1,
		desc = "Show stoic reading for specific date",
	},
	StoicNext = {
		handler = "handle_stoic_next_command",
		desc = "Show next stoic reading",
	},
	StoicPrev = {
		handler = "handle_stoic_prev_command",
		desc = "Show previous stoic reading",
	},
	StoicBookmark = {
		handler = "handle_stoic_bookmark_command",
		desc = "Toggle bookmark on current stoic entry",
	},
	StoicBookmarks = {
		handler = "handle_stoic_bookmarks_command",
		desc = "Show all bookmarked stoic entries",
	},
}

-- Single require call for the module
local stoic_module = nil

local function get_stoic_module()
	if not stoic_module then
		stoic_module = require("stoic")
	end
	return stoic_module
end

-- Create all commands in a single loop
for command_name, config in pairs(commands) do
	local command_opts = {
		desc = config.desc,
	}

	if config.nargs then
		command_opts.nargs = config.nargs
	end

	vim.api.nvim_create_user_command(command_name, function(opts)
		local module = get_stoic_module()
		module[config.handler](opts)
	end, command_opts)
end

return require("stoic.init")

