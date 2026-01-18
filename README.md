# 🌃 stoic.nvim

> Daily stoic wisdom from within Neovim.

This plugin was inspired by this [Chrome extension](https://chromewebstore.google.com/detail/the-daily-stoic/pikckaaljkbdgdbgmjglecglbaolpgaj)

## Requirements

- **Neovim**: 0.7.0
- [snacks.nvim](https://github.com/folke/snacks.nvim) (optional)

## Features 📝

- 366 stoic entries from "The Daily Stoic" with quotes and commentary
- Navigate chronologically through entries
- Bookmark your favorite stoic passages
- Customizable window appearance and keymaps

## Installation 🏗️

[lazy.nvim](https://github.com/folke/lazy.nvim) 💤

```lua
{
  'prjctimg/stoic.nvim',
  opts = {
    window = {
      position = "center",
      width = 80,
      height = 30,
      border = "rounded"
    },
    keymaps = {
      next = "n",
      prev = "p",
      bookmark = "b",
      quit = "q"
    }
  }
}
```

## Usage

### Commands

```vim
:Stoic            " Show today's stoic reading
:StoicToday       " Show today's stoic reading (same as :Stoic)
:StoicDate Aug 16 " Go to August 16th entry
:StoicNext        " Show next stoic reading
:StoicPrev        " Show previous stoic reading
:StoicBookmark    " Toggle bookmark on current entry
:StoicBookmarks   " Show all bookmarked entries
```

### API

```lua
require('stoic').setup(config)
require('stoic').show_today()
require('stoic').show_date('Aug 16')
require('stoic').show_next()
require('stoic').show_prev()
require('stoic').toggle_bookmark()
require('stoic').show_bookmarks()
```

## Config ⚙️

```lua
{
  window = {
    position = "center",  -- Window position
    width = 80,          -- Window width
    height = 30,         -- Window height
    border = "rounded"   -- Window border style
  },
  keymaps = {
    next = "n",         -- Next entry keymap
    prev = "p",         -- Previous entry keymap
    bookmark = "b",     -- Toggle bookmark keymap
    quit = "q"          -- Quit window keymap
  },
  highlights = {
    title = "StoicTitle",       -- Highlight group for titles
    author = "StoicAuthor",     -- Highlight group for authors
    quote = "StoicQuote",       -- Highlight group for quotes
    commentary = "StoicCommentary" -- Highlight group for commentary
  }
}
```

## Data Source 📜

This plugin uses stoic readings based on "The Daily Stoic" by Ryan Holiday and Stephen Hanselman, containing 366 daily meditations with quotes from ancient Stoic philosophers.

