#!/usr/bin/env nvim -l

-- Add current directory to Lua path
package.path = package.path .. ";" .. vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua"

print("=== Navigation and Bookmark Test ===")

-- Load the plugin
local stoic = require("stoic")
stoic.setup()

-- Test navigation functionality
print("Testing navigation...")

local data = require("stoic.data")
local navigation = require("stoic.navigation")

-- Get today's entry
local today_entry = navigation.get_today_entry()
print("✓ Today's entry loaded:", today_entry.title)

-- Test date entry lookup
local aug_entry = navigation.get_date_entry("August 16")
if aug_entry then
  print("✓ Date lookup works:", aug_entry.title)
else
  print("❌ Date lookup failed")
end

-- Test navigation functions
local first_entry = data.get_data_by_index(1)
if first_entry then
  print("✓ First entry available:", first_entry.title)
  
  -- Test next/previous navigation
  local next_entry = data.get_next_data(1)
  if next_entry then
    print("✓ Next entry works:", next_entry.title)
  else
    print("❌ Next entry failed")
  end
  
  local prev_entry = data.get_prev_data(2)
  if prev_entry then
    print("✓ Previous entry works:", prev_entry.title)
  else
    print("❌ Previous entry failed")
  end
else
  print("❌ Could not get first entry")
end

-- Test bookmark functionality
print("\nTesting bookmarks...")

local bookmarks = require("stoic.bookmarks")

-- Test adding bookmarks with multiple entries
local test_entries = {first_entry, today_entry}
for i, entry in ipairs(test_entries) do
  if entry and entry.docId then
    local success = bookmarks.add_bookmark(entry)
    if success then
      print("✓ Added bookmark", i, "for:", entry.title)
    else
      print("❌ Failed to add bookmark", i)
    end
  end
end

-- Test getting all bookmarks
local all_bookmarks = bookmarks.get_all_bookmarks()
print("✓ Total bookmarks:", #all_bookmarks)

if #all_bookmarks > 0 then
  -- Test bookmark checking
  local is_bookmarked = bookmarks.is_bookmarked(test_entries[1].docId)
  print("✓ Bookmark check works:", is_bookmarked)
  
  -- Test bookmark removal
  local remove_success = bookmarks.remove_bookmark(test_entries[1].docId)
  if remove_success then
    print("✓ Bookmark removal works")
    local remaining_bookmarks = bookmarks.get_all_bookmarks()
    print("✓ Remaining bookmarks:", #remaining_bookmarks)
  else
    print("❌ Bookmark removal failed")
  end
end

-- Test data integrity
print("\nTesting data integrity...")

-- Test docId lookup
if #all_bookmarks > 0 then
  local test_bookmark = all_bookmarks[1]
  local full_entry = data.get_data_by_docId(test_bookmark.docId)
  if full_entry and full_entry.title == test_bookmark.title then
    print("✓ DocId lookup maintains entry integrity")
  else
    print("❌ DocId lookup failed")
  end
end

-- Test edge cases
print("\nTesting edge cases...")

-- Test navigation with invalid index
local invalid_next = data.get_next_data(nil)
if invalid_next then
  print("✓ Next entry handles nil index")
else
  print("❌ Next entry fails with nil index")
end

local invalid_prev = data.get_prev_data(nil)
if invalid_prev then
  print("✓ Previous entry handles nil index")
else
  print("❌ Previous entry fails with nil index")
end

-- Test boundary navigation
local total_entries = #data.get_all_data()
local last_entry = data.get_data_by_index(total_entries)
if last_entry then
  local next_after_last = data.get_next_data(total_entries)
  if next_after_last then
    print("✓ Next after last wraps to first")
  else
    print("❌ Next after last failed")
  end
  
  local prev_before_first = data.get_prev_data(1)
  if prev_before_first then
    print("✓ Previous before first wraps to last")
  else
    print("❌ Previous before first failed")
  end
end

print("\n=== Navigation and Bookmark Test Complete ===")