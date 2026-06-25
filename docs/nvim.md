# Neovim

[Neovim](https://neovim.io) is the **editor**. This config is a **minimal,
single-file `init.lua`** you can read top to bottom in a couple of minutes. It
started from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) but has
been deliberately stripped back to a bare base — good defaults, a few keymaps,
and a colorscheme — so there's nothing in it you can't yet explain.

Everything heavier (treesitter, a fuzzy finder, LSP, autocompletion, formatting,
snippets, git signs, which-key) was **removed on purpose**. It's all recoverable
from git history when you're ready to grow into it; until then it's not config
you're driving blind.

- Your config: `nvim/init.lua` → symlinked to `~/.config/nvim` (Linux) /
  `%LOCALAPPDATA%\nvim` (Windows)
- Requires **Neovim 0.12+** (uses the built-in `vim.pack` plugin manager);
  `install.sh` installs the latest stable as a user binary because apt's is too old.
- Kickstart upstream, if you want the full version back:
  <https://github.com/nvim-lua/kickstart.nvim>

> **Read `init.lua` top to bottom.** It's ~140 lines, organized into three numbered
> sections and written to teach. This guide is the map; the file is the territory.

---

## How it's organized

```
nvim/
  init.lua                 # the entire config — one file
```

(`vim.pack` writes a `nvim-pack-lock.json` here at runtime to pin plugin
versions; it's auto-generated and gitignored.)

`init.lua` is split into three `do ... end` blocks so each section's local
variables stay contained:

| Section | What it does                                              |
| ------- | --------------------------------------------------------- |
| 1 Options    | numbers, clipboard, search, splits, undo            |
| 2 Keymaps    | window navigation, `<Esc>` clears search, yank flash |
| 3 Colorscheme| `vim.pack` intro + Tokyo Night (Night)              |

### Plugin management with `vim.pack`

Only one plugin is installed: `folke/tokyonight.nvim` (the colorscheme).

| Action            | Command                       |
| ----------------- | ----------------------------- |
| Install plugins   | automatically on startup      |
| Update plugins    | `:lua vim.pack.update()`      |
| List plugins      | `:lua = vim.pack.get()`       |
| Remove a plugin   | delete its `vim.pack.add` line, restart, then `:lua vim.pack.del { 'name' }` |

---

## Day-to-day usage

`<leader>` is **Space**. The whole custom keymap surface fits in one short table —
everything else is stock Neovim:

| Keys               | Action                                       |
| ------------------ | -------------------------------------------- |
| `<C-h/j/k/l>`      | Move focus between split windows             |
| `<Esc>`            | Clear search highlight                       |
| `<Esc><Esc>`       | Exit terminal mode (in a `:terminal` buffer) |

That's the lot — few enough to keep in your head. For finding/opening files
without a fuzzy finder, the built-ins are `:e <path>` (Tab-completes), `:find`,
and `:b <name>` to switch buffers. Adding [Telescope](https://github.com/nvim-telescope/telescope.nvim)
back is the natural first upgrade when you want frecency/grep search.

---

## Common tweaks

**Change options or keymaps** — Sections 1 and 2 at the top of `init.lua`.

**Add a plugin** — add a `vim.pack.add` line in the relevant section (or a new
`do ... end` block) and call its `setup`:
```lua
vim.pack.add { 'https://github.com/tpope/vim-fugitive' }
```
Restart, or run `:lua vim.pack.update()`.

**Want treesitter, a fuzzy finder, LSP, completion, or formatting back?** Those
are the natural next steps once the basics feel automatic. Fuller versions are in
this repo's git history — `git log -- nvim/init.lua` — or pull the relevant section from
[kickstart upstream](https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua).
Re-add it one section at a time so you understand each piece.

---

## Troubleshooting

- **`vim.pack` is nil / errors on startup** — your Neovim is older than 0.12.
  Check `nvim --version`; re-run the installer to get the user-binary build, and
  make sure it wins on `PATH` (on Windows a stale `C:\Program Files\Neovim` can
  shadow it — the installer warns about this).
- **A plugin won't load** — `:checkhealth` is your friend.
- **Want a clean slate** — plugin data lives in `~/.local/share/nvim` and
  `~/.local/state/nvim` (Linux) or `%LOCALAPPDATA%\nvim-data` (Windows), outside
  this repo; remove those to fully reset.
