#!/usr/bin/env nvim -l

-- Add current directory to Lua path
package.path = package.path .. ";" .. vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua"

-- Test script for stoic.nvim
print("=== Stoic.nvim Test ===")

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

-- Test formatting
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

print("=== All tests passed! ===")