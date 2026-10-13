# 🌃 stoic.nvim

> Daily stoic wisdom from within Neovim inspired by this [Chrome extension](https://chromewebstore.google.com/detail/the-daily-stoic/pikckaaljkbdgdbgmjglecglbaolpgaj)

<a href="https://asciinema.org/a/769180" target="_blank"><img src="https://asciinema.org/a/769180.svg" /></a>

> [!IMPORTANT]
>
> This plugin uses content based on "The Daily Stoic" by Ryan Holiday and Stephen Hanselman, containing 366 daily meditations with quotes from ancient Stoic philosophers.

## Requirements

- **Neovim**: >= 0.11.0
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
    daily_reading = true,
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

## Usage 🛠️

### Commands ⌨️

```vim
:Stoic            " Show today's stoic reading
:StoicToday       " Show today's stoic reading (same as :Stoic)
:StoicDate Aug 16 " Go to August 16th entry
:StoicNext        " Show next stoic reading
:StoicPrev        " Show previous stoic reading
:StoicBookmark    " Toggle bookmark on current entry
:StoicBookmarks   " Show all bookmarked entries
```

### API 🌕

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
  daily_reading = false,  -- Show daily reading on Neovim launch
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

## Contributors

<!-- CONTRIBUTORS -->
<p align="left">
  <a href="https://github.com/prjctimg"><img src="https://github.com/prjctimg.png?size=80" width="50" height="50" style="border-radius:50%;margin:4px;" alt="prjctimg"/></a>
</p>
<!-- /CONTRIBUTORS -->

> **License ⚖️**
>
> (c) [Dean Tarisai](https://prjctimg.me)
>
> Released under the [GPL-3.0](LICENSE) License.
