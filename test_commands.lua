#!/usr/bin/env nvim -l

-- Add current directory to Lua path
package.path = package.path .. ";" .. vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua"

print("=== Command Functionality Test ===")

-- Load the plugin
local stoic = require("stoic")
stoic.setup()

-- Test command handlers exist and are callable
print("Testing command handlers...")

local handlers = {
  "handle_stoic_command",
  "handle_stoic_today_command", 
  "handle_stoic_date_command",
  "handle_stoic_next_command",
  "handle_stoic_prev_command",
  "handle_stoic_bookmark_command",
  "handle_stoic_bookmarks_command"
}

for _, handler in ipairs(handlers) do
  if stoic[handler] and type(stoic[handler]) == "function" then
    print("✓", handler, "available")
  else
    print("❌", handler, "missing or not a function")
  end
end

-- Test state management
print("\nTesting state management...")

local state = stoic._get_state()
if state then
  print("✓ State management works")
  print("  - Setup complete:", state.setup_complete)
  print("  - Data loaded:", state.data_loaded)
  print("  - Bookmarks loaded:", state.bookmarks_loaded)
  print("  - Window open:", state.window_open)
else
  print("❌ State management failed")
end

-- Test configuration validation
print("\nTesting configuration validation...")

local valid_config = {
  window = { width = 80 },
  keymaps = { next = "n" }
}

local invalid_config1 = {
  window = "not a table"
}

local invalid_config2 = {
  keymaps = "not a table"
}

-- Reset setup for testing
stoic._reset_setup()

if stoic._validate_config(valid_config) then
  print("✓ Valid configuration passes validation")
else
  print("❌ Valid configuration fails validation")
end

if not stoic._validate_config(invalid_config1) then
  print("✓ Invalid window config fails validation")
else
  print("❌ Invalid window config passes validation")
end

if not stoic._validate_config(invalid_config2) then
  print("✓ Invalid keymaps config fails validation")
else
  print("❌ Invalid keymaps config passes validation")
end

-- Test utility functions
print("\nTesting utility functions...")

-- Test cache clearing
stoic.clear_cache()
print("✓ Cache clearing works")

-- Test data reloading
local reload_success = stoic.reload_data()
if reload_success then
  print("✓ Data reloading works")
else
  print("❌ Data reloading failed")
end

-- Test bookmarks reloading
local bookmark_reload_success = stoic.reload_bookmarks()
if bookmark_reload_success then
  print("✓ Bookmarks reloading works")
else
  print("❌ Bookmarks reloading failed")
end

-- Test data access without setup
stoic._reset_setup()

local data = require("stoic.data")
local first_entry = data.get_data_by_index(1)
if first_entry then
  print("✓ Data access works without explicit setup")
else
  print("❌ Data access fails without explicit setup")
end

print("\n=== Command Functionality Test Complete ===")