# typist.nvim

Practice touch typing inside Neovim with your actual code

## Requirements

- [Neovim 0.10+](https://github.com/neovim/neovim/releases)

## Installation

typist.nvim supports multiple plugin managers

<details>
<summary><strong>lazy.nvim</strong></summary>

```lua
{
    "Goose97/typist.nvim",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
        require("typist").setup({
            -- Configuration here, or leave empty to use defaults
        })
    end
}
```
</details>

<details>
<summary><strong>packer.nvim</strong></summary>

```lua
use({
    "Goose97/typist.nvim",
    tag = "*", -- Use for stability; omit to use `main` branch for the latest features
    config = function()
        require("typist").setup({
            -- Configuration here, or leave empty to use defaults
        })
    end
})
```
</details>

<details>
<summary><strong>mini.deps</strong></summary>

```lua
local MiniDeps = require("mini.deps");

MiniDeps.add({
    source = "Goose97/typist.nvim",
})

require("typist").setup({
    -- Configuration here, or leave empty to use defaults
})
```
</details>

## Setup

You will need to call `require("typist").setup()` to intialize the plugin.

## Usage

To start a practice session, run `:TypistStart`. To stop a practice session, press `Escape` or run `:TypistStop`.

## Highlight groups
<!-- hl_start -->

| Highlight Group | Default Group | Description |
| ----------------------------- | ----------------------- | ------------------------------ |
| **Typist.Overlay** | _None_ | The grey overlay over the buffer content |
| **Typist.Correct** | _None_ | The correct text |
| **Typist.Incorrect** | _None_ | The incorrect text |
| **Typist.CurrentLine** | _LineNr_ | The current line indicator |

<!-- hl_end -->
