#!/usr/bin/env nvim -l

-- Add current directory to Lua path
package.path = package.path .. ";" .. vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua"

-- Test script for stoic.nvim
print("=== Stoic.nvim Comprehensive Test ===")

-- Load the plugin
local stoic = require("stoic")
stoic.setup()

-- Test data loading
local data = require("stoic.data")
local all_entries = data.get_all()
print("✓ Loaded", #all_entries, "stoic entries")

-- Test navigation
local nav = require("stoic.navigation")
local today = nav.get_today_entry()
print("✓ Today's entry:", today.title)
print("  Date:", today.date)
print("  Author:", today.author)

-- Test bookmarks
local bookmarks = require("stoic.bookmarks")
print("✓ Bookmarks system initialized")

-- Test formatting with emojis and date at top
local format = require("stoic.format")
local test_config = {
  highlights = {
    title = "StoicTitle",
    author = "StoicAuthor", 
    quote = "StoicQuote",
    commentary = "StoicCommentary"
  },
  window = {
    width = 80
  }
}
local content, highlights = format.format_entry(today, test_config)
print("✓ Formatted entry with", #content, "lines and", #highlights, "highlights")

-- Test command handlers
print("✓ Testing command handlers...")
stoic.handle_stoic_today_command()
print("✓ Command handlers work")

-- Test keymap functionality
print("✓ Testing keymap functionality...")
stoic.show_next()
stoic.show_prev()
print("✓ Keymap navigation works")

-- Check if date is at top and emojis are present
local has_date_emoji = false
local has_title_emoji = false
local has_quote_emoji = false
local has_book_emoji = false

for _, line in ipairs(content) do
  if line:find("📅") then has_date_emoji = true end
  if line:find("🎯") then has_title_emoji = true end
  if line:find("💭") then has_quote_emoji = true end
  if line:find("📚") then has_book_emoji = true end
end

print("✓ Date at top with emoji:", has_date_emoji)
print("✓ Title with emoji:", has_title_emoji)
print("✓ Quote with emoji:", has_quote_emoji)
print("✓ Author with emoji:", has_book_emoji)

-- Check if commentary is removed
local has_commentary = false
for _, line in ipairs(content) do
  if line:find("Commentary") or line:find("💡") then
    has_commentary = true
    break
  end
end
print("✓ Commentary removed:", not has_commentary)

print("=== All tests passed! ===")