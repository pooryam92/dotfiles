# Neovim

[Neovim](https://neovim.io) is the **editor**. This config is based on
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) — a single,
heavily-commented `init.lua` meant as a *starting point you own*, not a framework
that hides things. On top of stock kickstart we add **Tokyo Night** (to
match the rest of the setup) and **in-buffer Markdown rendering**.

- Kickstart upstream: <https://github.com/nvim-lua/kickstart.nvim>
- Your config: `nvim/` → symlinked to `~/.config/nvim`
- Requires **Neovim 0.12+** (uses the built-in `vim.pack` plugin manager);
  `install.sh` installs the latest stable as a user binary because apt's is too
  old.

> The whole point of kickstart: **read `init.lua` top to bottom.** It's written
> to teach. This guide covers the shape and our changes — the file itself is the
> real documentation.

---

## How it's organized

```
nvim/
  init.lua                      # the entire base config (kickstart)
  lua/
    kickstart/plugins/...       # optional extras kickstart ships (mostly off)
    custom/plugins/init.lua     # OUR additions (loaded at the end of init.lua)
```

- **`init.lua`** sets options/keymaps and adds plugins with
  `vim.pack.add { ... }` (Neovim's native manager — no lazy.nvim).
- **`lua/custom/plugins/init.lua`** is where our own plugins go. `init.lua` ends
  with `require 'custom.plugins'` (we uncommented that line) so it loads last.

### Plugin management with `vim.pack`

| Action            | Command                       |
| ----------------- | ----------------------------- |
| Plugins install   | automatically on startup      |
| Update plugins    | `:lua vim.pack.update()`      |
| List plugins      | `:lua = vim.pack.get()`       |
| Remove a plugin   | delete its `vim.pack.add` line, then `:lua vim.pack.update()` |

---

## What we changed from stock kickstart

### 1. Colorscheme → Tokyo Night (`init.lua`, "Colorscheme" section)

```lua
vim.pack.add { gh 'folke/tokyonight.nvim' }
require('tokyonight').setup {
  style = 'night', -- matches WezTerm / Zellij / Starship
  styles = { comments = { italic = false } },
}
vim.cmd.colorscheme 'tokyonight-night'
```
Other styles: `tokyonight-storm`, `tokyonight-moon`, `tokyonight-day`.

### 2. Markdown rendering (`lua/custom/plugins/init.lua`)

```lua
vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }
require('render-markdown').setup { file_types = { 'markdown' } }
vim.keymap.set('n', '<leader>tm', '<cmd>RenderMarkdown toggle<CR>',
  { desc = '[T]oggle [M]arkdown render' })
```

[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)
renders headings, code blocks, lists, tables, checkboxes, and callouts **right in
the buffer** — no browser. It de-renders the line your cursor is on so you can
still edit raw markdown. It uses the `markdown` / `markdown_inline` treesitter
parsers (kickstart already installs them) and the icons from `mini.nvim`.

---

## Day-to-day usage

`<leader>` is **Space** (kickstart default). A few of the most useful built-ins:

| Keys          | Action                                  |
| ------------- | --------------------------------------- |
| `<leader>sf`  | Search files (Telescope find_files)     |
| `<leader>sg`  | Search by grep (live grep)              |
| `<leader>sh`  | Search help                             |
| `<leader>sk`  | Search keymaps                          |
| `<leader><leader>` | Switch open buffers                |
| `grn`         | LSP rename                              |
| `gra`         | LSP code action                         |
| `grd` / `grr` | Goto definition / references            |
| `<leader>tm`  | **Toggle markdown rendering** (ours)    |
| `<leader>f`   | Format buffer (conform.nvim)            |

- **Read a doc nicely:** `nvim docs/zellij.md` — it renders automatically. Hit
  `<leader>tm` to flip to raw text.
- **Which-key:** pause after `<leader>` and a popup shows what's available — the
  best way to discover the rest.

---

## Common tweaks

**Add a plugin** — drop it in `lua/custom/plugins/init.lua`:
```lua
vim.pack.add { 'https://github.com/tpope/vim-fugitive' }
```
(Run `:lua vim.pack.update()` or restart.)

**Enable one of kickstart's optional extras** — uncomment its `require` near the
bottom of `init.lua`, e.g.:
```lua
require 'kickstart.plugins.autopairs'
require 'kickstart.plugins.gitsigns'
```

**Add an LSP server** — kickstart installs servers via Mason; add it to the
`servers` table in the LSP section of `init.lua` (it's commented with examples).

**Change options/keymaps** — they're at the top of `init.lua`, clearly grouped
under `[[ Setting options ]]` and `[[ Basic Keymaps ]]`.

---

## Troubleshooting

- **`vim.pack` is nil / errors on startup** — your Neovim is older than 0.12.
  Check `nvim --version`; re-run `install.sh` to get the user-binary build, and
  make sure `~/.local/bin` is ahead of `/usr/bin` on `PATH` (it is, via
  `zsh/.zshrc`).
- **Markdown shows raw with icon boxes (□)** — Nerd Font not active in the
  terminal; see the WezTerm guide.
- **A plugin won't load** — `:checkhealth` is your friend; for treesitter parser
  issues, `:checkhealth nvim-treesitter`.
- **Want a clean slate** — plugin data lives in `~/.local/share/nvim` and
  `~/.local/state/nvim` (outside this repo); remove those to fully reset.
