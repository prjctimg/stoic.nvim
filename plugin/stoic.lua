-- Plugin registration for stoic.nvim
-- Minimal plugin initialization - all logic in init.lua

-- Register user commands using centralized handlers
vim.api.nvim_create_user_command('Stoic', function()
  require('stoic').handle_stoic_command()
end, { desc = 'Show today\'s stoic reading' })

vim.api.nvim_create_user_command('StoicToday', function()
  require('stoic').handle_stoic_today_command()
end, { desc = 'Show today\'s stoic reading' })

vim.api.nvim_create_user_command('StoicDate', function(opts)
  require('stoic').handle_stoic_date_command(opts)
end, { 
  nargs = 1,
  desc = 'Show stoic reading for specific date'
})

vim.api.nvim_create_user_command('StoicNext', function()
  require('stoic').handle_stoic_next_command()
end, { desc = 'Show next stoic reading' })

vim.api.nvim_create_user_command('StoicPrev', function()
  require('stoic').handle_stoic_prev_command()
end, { desc = 'Show previous stoic reading' })

vim.api.nvim_create_user_command('StoicBookmark', function()
  require('stoic').handle_stoic_bookmark_command()
end, { desc = 'Toggle bookmark on current stoic entry' })

vim.api.nvim_create_user_command('StoicBookmarks', function()
  require('stoic').handle_stoic_bookmarks_command()
end, { desc = 'Show all bookmarked stoic entries' })

-- Auto setup with default configuration when plugin is loaded
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    -- Only auto-setup if not already configured
    if not vim.g.stoic_setup then
      require('stoic').setup()
      vim.g.stoic_setup = true
    end
  end,
  desc = 'Auto-initialize stoic.nvim'
})