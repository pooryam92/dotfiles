# Neovim

[Neovim](https://neovim.io) is the **editor**. This config is a **minimal,
single-file `init.lua`** you can read top to bottom in a couple of minutes. It
started from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) but has
been deliberately stripped back to a bare base — good defaults, a few keymaps,
and a colorscheme — so there's nothing in it you can't yet explain.

Everything heavier (treesitter, a fuzzy finder, LSP, autocompletion, formatting,
snippets, git signs, which-key) was **removed on purpose** — and staying out.
**This config is complete for its job**: quick file edits, git commit messages,
and `Ctrl+X Ctrl+E` from the shell. Project editing belongs to Zed and the
JetBrains IDEs, so nvim doesn't need to grow into a second IDE. (If that decision
is ever revisited, the fuller configs live in git history.)

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
| 2 Keymaps    | window navigation + splits, `<Esc>` clears search, yank flash |
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
| `<leader>-`        | Split window below (mirrors IdeaVim)         |
| `<leader>\|`       | Split window right (mirrors IdeaVim)         |
| `<Esc>`            | Clear search highlight                       |
| `<Esc><Esc>`       | Exit terminal mode (in a `:terminal` buffer) |

That's the lot — few enough to keep in your head. The `<leader>-` / `<leader>|`
split maps match the IdeaVim config so split-create feels the same across editors;
**file-find and AI leader maps are deliberately left out** here — IdeaVim and Zed
have them, and that's where project editing happens. For finding/opening files
in nvim, the built-ins are `:e <path>` (Tab-completes), `:find`, and
`:b <name>` to switch buffers — plenty for the quick-edit role this config plays.

---

## Common tweaks

**Change options or keymaps** — Sections 1 and 2 at the top of `init.lua`.

**Add a plugin** — add a `vim.pack.add` line in the relevant section (or a new
`do ... end` block) and call its `setup`:
```lua
vim.pack.add { 'https://github.com/tpope/vim-fugitive' }
```
Restart, or run `:lua vim.pack.update()`.

**Want treesitter, a fuzzy finder, LSP, completion, or formatting back?** The
standing decision is *no* — Zed/JetBrains cover project editing. If that ever
changes, fuller versions are in this repo's git history
(`git log -- nvim/init.lua`) or in
[kickstart upstream](https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua);
re-add one section at a time so you understand each piece.

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
