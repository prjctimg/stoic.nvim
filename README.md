# stoic.nvim

A Neovim plugin that displays daily stoic readings with navigation, bookmarks, and proper text formatting.

## Features

- **Daily Stoic Readings**: 366 stoic entries from "The Daily Stoic" with quotes and commentary
- **Navigation**: Navigate chronologically through entries (previous/next/today/date)
- **Bookmarks**: Save and manage your favorite stoic passages
- **Modern UI**: Integration with snacks.nvim with fallback to native APIs
- **Flexible Configuration**: Customizable window appearance and keymaps
- **Text Formatting**: Proper text wrapping with literal line break handling
- **Highlights**: Syntax highlighting for different sections (title, author, quote, commentary)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'yourname/stoic.nvim',
  opts = {
    -- Optional configuration
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

### Keymaps

When a stoic window is open, these default keymaps are available:

- `n` - Next entry
- `p` - Previous entry
- `b` - Toggle bookmark
- `q` - Quit window

### Lua API

```lua
require('stoic').setup(config)
require('stoic').show_today()
require('stoic').show_date('Aug 16')
require('stoic').show_next()
require('stoic').show_prev()
require('stoic').toggle_bookmark()
require('stoic').show_bookmarks()
```

## Configuration

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

## Dependencies

- **Optional**: [snacks.nvim](https://github.com/folke/snacks.nvim) for enhanced UI
- **Neovim**: Version 0.7.0 or later

## File Structure

```
lua/
├── stoic/
│   ├── init.lua          # Main plugin entry point
│   ├── data.lua          # Data loading and management
│   ├── window.lua        # Window creation and management
│   ├── format.lua        # Text formatting and display
│   ├── navigation.lua    # Navigation between entries
│   └── bookmarks.lua     # Bookmark functionality
├── stoic.lua             # Plugin loader
plugin/
└── stoic.lua             # Plugin registration
stoic.json               # Stoic data (366 entries)
```

## Data Source

This plugin uses stoic readings based on "The Daily Stoic" by Ryan Holiday and Stephen Hanselman, containing 366 daily meditations with quotes from ancient Stoic philosophers.

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit issues and enhancement requests.