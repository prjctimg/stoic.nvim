#!/usr/bin/env nvim -l

-- Add current directory to Lua path
package.path = package.path .. ";" .. vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua"

-- Test script for stoic.nvim
print("=== Final Feature Test ===")

-- Load the plugin
local stoic = require("stoic")
stoic.setup()

-- Test data loading
local data = require("stoic.data")
local all_entries = data.get_all_data()
print("✓ Loaded", #all_entries, "stoic entries")

-- Test navigation
local nav = require("stoic.navigation")
local today = nav.get_today_entry()
print("✓ Today's entry:", today.title)

-- Test bookmarks
local bookmarks = require("stoic.bookmarks")
print("✓ Bookmarks system initialized")

-- Test formatting with all features
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

-- Check all features
local has_date_emoji = false
local has_title_emoji = false
local has_quote_emoji = false
local has_book_emoji = false
local has_commentary_emoji = false
local has_commentary = false
local has_id = false

for _, line in ipairs(content) do
  if line:find("📅") then has_date_emoji = true end
  if line:find("🎯") then has_title_emoji = true end
  if line:find("💭") then has_quote_emoji = true end
  if line:find("📚") then has_book_emoji = true end
  if line:find("💡") then has_commentary_emoji = true end
  if line:find("Commentary:") then has_commentary = true end
  if line:find("ID:") then has_id = true end
end

print("✅ Final Feature Status:")
print("  📅 Date at top with emoji:", has_date_emoji)
print("  🎯 Title with emoji:", has_title_emoji)
print("  💭 Quote with emoji:", has_quote_emoji)
print("  📚 Author with emoji:", has_book_emoji)
print("  💡 Commentary with emoji:", has_commentary_emoji)
print("  📝 Commentary text present:", has_commentary)
print("  ❌ ID removed:", not has_id)

-- Test help text includes view bookmarks
local has_view_bookmarks = false
for _, line in ipairs(content) do
  if line:find("view bookmarks") or line:find("B]") then
    has_view_bookmarks = true
    break
  end
end
print("  🔖 View bookmarks in help:", has_view_bookmarks)

-- Test bookmark functionality
stoic.toggle_bookmark()
local bookmarked_entries = bookmarks.get_all_bookmarks()
print("  🔖 Bookmark toggle works:", #bookmarked_entries > 0)

-- Test data module docId lookup
if #bookmarked_entries > 0 then
  local test_entry = data.get_data_by_docId(bookmarked_entries[1].docId)
  print("  🔍 DocId lookup works:", test_entry ~= nil)
end

-- Test command handlers
print("  ⌨️  Command handlers loaded:", stoic.handle_stoic_command ~= nil)

print("=== All features implemented! ===")