# Neovim

[Neovim](https://neovim.io) is the **editor**. This config is a **lean,
single-file `init.lua`** you can read top to bottom in a few minutes. It started
from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) but has been
deliberately stripped back to the basics — good defaults, a few keymaps, syntax
highlighting, and a fuzzy finder — so there's nothing in it you can't yet explain.

The heavier kickstart machinery (LSP, autocompletion, formatting, snippets,
git signs, which-key, in-buffer Markdown rendering) was **removed on purpose**.
It's all recoverable from git history when you're ready to grow into it; until
then it's not config you're driving blind.

- Your config: `nvim/init.lua` → symlinked to `~/.config/nvim` (Linux) /
  `%LOCALAPPDATA%\nvim` (Windows)
- Requires **Neovim 0.12+** (uses the built-in `vim.pack` plugin manager);
  `install.sh` installs the latest stable as a user binary because apt's is too old.
- Kickstart upstream, if you want the full version back:
  <https://github.com/nvim-lua/kickstart.nvim>

> **Read `init.lua` top to bottom.** It's ~230 lines, organized into six numbered
> sections and written to teach. This guide is the map; the file is the territory.

---

## How it's organized

```
nvim/
  init.lua                 # the entire config — one file
  nvim-pack-lock.json      # pinned plugin versions (vim.pack writes this)
```

`init.lua` is split into six `do ... end` blocks so each section's local
variables stay contained:

| Section | What it does                                              |
| ------- | --------------------------------------------------------- |
| 1 Options    | numbers, clipboard, search, splits, undo            |
| 2 Keymaps    | window navigation, `<Esc>` clears search, yank flash |
| 3 Plugins    | `vim.pack` intro + the post-install build hook      |
| 4 Colorscheme| Tokyo Night (Night)                                 |
| 5 Treesitter | syntax highlighting + auto-installed parsers        |
| 6 Telescope  | fuzzy find files / grep / buffers                   |

### Plugin management with `vim.pack`

Only five plugins are installed: `folke/tokyonight.nvim`, `nvim-treesitter`,
`telescope.nvim` + `plenary.nvim`, and (when `make` is present)
`telescope-fzf-native.nvim`.

| Action            | Command                       |
| ----------------- | ----------------------------- |
| Install plugins   | automatically on startup      |
| Update plugins    | `:lua vim.pack.update()`      |
| List plugins      | `:lua = vim.pack.get()`       |
| Remove a plugin   | delete its `vim.pack.add` line, restart, then `:lua vim.pack.del { 'name' }` |

---

## Day-to-day usage

`<leader>` is **Space**. The whole keymap surface fits in one table:

| Keys               | Action                                       |
| ------------------ | -------------------------------------------- |
| `<leader>sf`       | Search **f**iles (Telescope `find_files`)    |
| `<leader>sg`       | Search by **g**rep (live grep across project)|
| `<leader>sw`       | Search current **w**ord                      |
| `<leader>sh`       | Search **h**elp tags                         |
| `<leader>sk`       | Search **k**eymaps                           |
| `<leader>s.`       | Recent files (oldfiles)                      |
| `<leader>sn`       | Search the **n**eovim config dir             |
| `<leader>/`        | Fuzzy-find within the current buffer         |
| `<leader><leader>` | Switch between open buffers                  |
| `<C-h/j/k/l>`      | Move focus between split windows             |
| `<Esc>`            | Clear search highlight                       |

That's the lot — no `which-key` popup anymore, because there are few enough
mappings to keep in your head. Inside any Telescope picker, press `?` (normal
mode) or `<C-/>` (insert mode) to see that picker's own keys.

If you only learn three: `<leader>sf` to open files, `<leader>sg` to grep, and
`<leader><leader>` to hop between what's already open.

---

## Common tweaks

**Change options or keymaps** — Sections 1 and 2 at the top of `init.lua`.

**Add a plugin** — add a `vim.pack.add` line in the relevant section (or a new
`do ... end` block) and call its `setup`:
```lua
vim.pack.add { 'https://github.com/tpope/vim-fugitive' }
```
Restart, or run `:lua vim.pack.update()`.

**Add another treesitter language** — add it to the `install { ... }` list in
Section 5. (Files in already-installed languages highlight automatically; new
languages auto-install on first open if a parser exists.)

**Want LSP / completion / formatting back?** That's the natural next step once
the basics feel automatic. The full kickstart version is in this repo's git
history — `git log -- nvim/init.lua` — or pull the relevant section from
[kickstart upstream](https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua).
Re-add it one section at a time so you understand each piece.

---

## Troubleshooting

- **`vim.pack` is nil / errors on startup** — your Neovim is older than 0.12.
  Check `nvim --version`; re-run the installer to get the user-binary build, and
  make sure it wins on `PATH` (on Windows a stale `C:\Program Files\Neovim` can
  shadow it — the installer warns about this).
- **A plugin won't load** — `:checkhealth` is your friend; for parser issues,
  `:checkhealth nvim-treesitter`.
- **Treesitter parser won't compile** — needs a C compiler (`zig` on Windows,
  installed by the installer). See the [Windows guide](windows.md) if compilation
  hangs.
- **Want a clean slate** — plugin data lives in `~/.local/share/nvim` and
  `~/.local/state/nvim` (Linux) or `%LOCALAPPDATA%\nvim-data` (Windows), outside
  this repo; remove those to fully reset.
