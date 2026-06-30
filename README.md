# dotfiles

A clean terminal environment for **Linux** (Pop!_OS / Ubuntu) **and Windows**,
themed Tokyo Night end to end. One repo, two platforms — the same configs
are shared across both; only the shell differs (zsh on Linux, PowerShell on
Windows).

| Layer        | Tool                                              |
| ------------ | ------------------------------------------------- |
| Terminal     | [WezTerm](https://wezfurlong.org/wezterm/) — runs natively on Linux & Windows; also the multiplexer (built-in panes/tabs/splits) |
| Shell        | zsh (Linux) / [PowerShell 7](https://learn.microsoft.com/powershell/) (Windows) |
| Prompt       | [Starship](https://starship.rs)                   |
| Navigation   | [zoxide](https://github.com/ajeetdsouza/zoxide) — smarter `cd` (`z`/`zi`) |
| Editor       | [Neovim](https://neovim.io) — minimal single-file config (Tokyo Night) |
| GUI editor   | [Zed](https://zed.dev) — fast GPU editor, Vim mode + JetBrains Islands Dark (shared `settings.json`/`keymap.json`) |
| IDE editing  | [IdeaVim](https://github.com/JetBrains/ideavim) — Vim plugin for JetBrains IDEs (`.ideavimrc`) |
| AI coding    | [Claude Code](https://docs.claude.com/en/docs/claude-code) — themed status line + synced settings |

> **Why WezTerm instead of Ghostty?** Ghostty has no official Windows build, so
> the terminal layer would fork across machines. WezTerm is cross-platform and
> Lua-configured, so a single `wezterm.lua` serves every OS.

 # Learn it

In-depth, beginner-friendly guides to using and configuring each tool — grounded
in the actual config in this repo:

- [WezTerm](docs/wezterm.md) — the terminal *and* multiplexer: fonts, themes, panes/tabs, the OS branch
- [zsh](docs/zsh.md) — the shell: history, completion, plugins, aliases
- [Starship](docs/starship.md) — the prompt: modules, format, styling
- [zoxide](docs/zoxide.md) — smarter `cd`: jump to frecent dirs with `z`/`zi`
- [Neovim](docs/nvim.md) — minimal single-file config: sensible defaults, keymaps, Tokyo Night
- [Zed](docs/zed.md) — the GUI editor: Vim mode, JetBrains Islands Dark theme, fonts, keymap (**opt-in install**: `zed/install-zed.{sh,ps1}`)
- [IdeaVim](docs/ideavim.md) — Vim in JetBrains IDEs: leader maps, IDE actions
- [Claude Code](docs/claude.md) — the AI agent: themed status line, synced settings
- [COSMIC on niri](docs/niri.md) — **opt-in, Linux-only**: COSMIC's shell on a scrollable-tiling compositor (`niri/install-cosmic-niri.sh`)
- [Windows](docs/windows.md) — **native Windows setup**: scoop, PowerShell profile, paths

## Quick start

### Linux (Pop!_OS / Ubuntu)

```sh
git clone https://github.com/pooryam92/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Windows (native — no WSL)

First run from Windows PowerShell 5.1 (pwsh 7 is installed by the script):

```powershell
git clone https://github.com/pooryam92/dotfiles $HOME\dotfiles
cd $HOME\dotfiles
powershell -ExecutionPolicy Bypass -File install.ps1
```

See [docs/windows.md](docs/windows.md) for prerequisites (Developer Mode for live
symlinks) and details.

Then open a fresh **WezTerm** window — it launches your shell with the Starship
prompt. Split with `Alt+\` / `Alt+-`, hop panes with `Alt+h/j/k/l` (see
[Keybindings](#keybindings) for the full set).

## What the installers do

Both are **idempotent** — safe to re-run. Anything already at a target path is
backed up to `<file>.bak.<timestamp>` before linking.

**`install.sh` (Linux)** installs apt packages (`zsh`, `git`, `fzf`, plugins,
etc.), **WezTerm** (official Fury apt repo), and **Starship**, **zoxide**,
**Neovim**, and **Claude Code** (official installers) as user binaries in
`~/.local/bin`. It installs the **JetBrainsMono Nerd Font**, symlinks the configs
(including Zed's), and sets **zsh** as the login shell (`chsh`). Steps using
`sudo` will prompt for your password.

**`install.ps1` (Windows)** uses [scoop](https://scoop.sh) (user-scope, no admin)
to install **PowerShell 7**, **WezTerm**, **Starship**, **zoxide**, **Neovim**,
plus `fzf` (fuzzy finder) and `win32yank` (Neovim's clipboard), the Nerd
Font, and the **PSFzf** module. It also installs **Claude Code** (its own native
installer, not scoop), then links the configs (including Zed's). See
[docs/windows.md](docs/windows.md).

These install the **terminal/CLI stack** only. **Zed** (the GUI editor) is a
GUI app, so — like the niri session below — it installs from its own script
(`zed/install-zed.sh` on Linux, `zed/install-zed.ps1` on Windows); the installers
above still symlink Zed's config either way. Zed self-updates, so the update
scripts don't track it.

### Keeping things updated

The **config files** are symlinks into this repo, so `git pull` is all it takes to
update them on every machine. The **tools** are install-once, though — re-running
`install.sh`/`install.ps1` skips anything already present and never upgrades it. To
bump the tools to their latest releases, use the companion update scripts:

```bash
./setup/update.sh check      # Linux: list ONLY what's behind (exit 1 if any); no changes
./setup/update.sh versions   # Linux: full installed-vs-latest table; no changes, no sudo
./setup/update.sh            # Linux: preview → confirm → upgrade → summary of what moved
```

```powershell
.\setup\update.ps1 -Check    # Windows: list what's behind via `scoop status`; no changes
.\setup\update.ps1 -Versions # Windows: full installed list (`scoop list`); no changes
.\setup\update.ps1           # Windows: preview → confirm → upgrade everything
```

`check` answers "what needs updating?" at a glance. A plain `update` first **shows
you the jump** (`starship 1.25.1 → 1.26.0`) with a **release-notes link** for each
tool, flags **major / 0.x-minor bumps with ⚠** (the ones most likely to break
something), and asks before changing anything — so you can read the changelog
first. Afterwards it prints a summary of exactly what moved.

These track *latest* rather than pinning versions (goal: stay simple) — the preview
lets you eyeball drift and breaking changes first. WezTerm (Linux) and Claude Code
self-update on their own (as does Zed, installed separately); Neovim's plugins
update from inside nvim with `:lua vim.pack.update()`.

## Layout

Most configs are **shared** between Linux and Windows and linked into place, so
edits here take effect immediately. Only the shell config differs.

The setup machinery lives in **`setup/`**: the link targets below are data in
[`setup/links.tsv`](setup/links.tsv) and the version-tracked tools in
[`setup/tools.tsv`](setup/tools.tsv), both read by the shared helpers in
`setup/lib.sh` / `setup/lib.ps1`. Adding a config or tool is a single manifest row
(plus a one-line action function for a tool that isn't a plain apt/scoop package).
Only `install.sh` / `install.ps1` stay at the repo root as the entry points.

| Repo file                | Linux target                  | Windows target                          |
| ------------------------ | ----------------------------- | --------------------------------------- |
| `wezterm/wezterm.lua`    | `~/.config/wezterm/wezterm.lua` | `%USERPROFILE%\.config\wezterm\wezterm.lua` |
| `starship/starship.toml` | `~/.config/starship.toml`     | `%USERPROFILE%\.config\starship.toml`   |
| `nvim/`                  | `~/.config/nvim`              | `%LOCALAPPDATA%\nvim` (junction)        |
| `zed/settings.json`      | `~/.config/zed/settings.json` | `%APPDATA%\Zed\settings.json`           |
| `zed/keymap.json`        | `~/.config/zed/keymap.json`   | `%APPDATA%\Zed\keymap.json`             |
| `intellij/.ideavimrc`    | `~/.ideavimrc`                | `%USERPROFILE%\.ideavimrc`              |
| `zsh/.zshrc`             | `~/.zshrc`                    | —                                       |
| `pwsh/profile.ps1`       | —                             | `$PROFILE.CurrentUserAllHosts`          |
| `claude/statusline.js`   | `~/.claude/statusline.js`     | `%USERPROFILE%\.claude\statusline.js`   |
| `claude/settings.json`   | `~/.claude/settings.json`     | `%USERPROFILE%\.claude\settings.json`   |
| `niri/config.kdl`                | `~/.config/niri/config.kdl`   | — (Linux-only; via `niri/install-cosmic-niri.sh`) |

After editing:

- **WezTerm** – auto-reloads on save (`ctrl+shift+r` forces it).
- **zsh** – `exec zsh` (or open a new shell). **PowerShell** – `. $PROFILE`.
- **Starship** – picked up on the next prompt.
- **Neovim** – restart `nvim` (plugins via `:lua vim.pack.update()`).
- **Zed** – applies settings/keymap edits on save; no reload.

## Keybindings

Panes and tabs are driven by **direct chords** — no prefix, no leader, no modes.
Almost everything is `Alt+<key>`, because `Alt` is free whereas `Ctrl+h`
(backspace) and `Ctrl+l` (clear) belong to the shell.

### Panes

| Key                        | Action                          |
| -------------------------- | ------------------------------- |
| `alt+\`                    | Split pane **right**            |
| `alt+-`                    | Split pane **down**             |
| `alt+h/j/k/l` or `alt+←↓↑→`| Move focus between panes        |
| `alt+shift+h/j/k/l`        | Resize the focused pane (repeat to nudge) |
| `alt+shift+[` / `alt+shift+]` | Rotate panes counter-/clockwise |
| `alt+z`                    | Zoom (toggle fullscreen pane)   |
| `alt+x`                    | Close the focused pane          |

> Mnemonic for splits: `\` ≈ a vertical divider (pane to the right); `-` ≈ a
> horizontal divider (pane below). `Alt`, not `Ctrl`, so `Ctrl+l` clear-screen
> and `Ctrl+h` backspace stay intact.

### Tabs

| Key                        | Action                          |
| -------------------------- | ------------------------------- |
| `alt+t`                    | New tab                         |
| `alt+w`                    | Close tab                       |
| `alt+[` / `alt+]`          | Previous / next tab             |
| `alt+1`–`alt+9`            | Jump to tab _N_                 |

### Scrollback & misc

| Key                        | Action                          |
| -------------------------- | ------------------------------- |
| `ctrl+s`                   | Copy mode — vim motions, `/` search, `y` yank |
| `ctrl+shift+r`             | Reload config                   |
| `ctrl+=` / `ctrl+-` / `ctrl+0` | Font size up / down / reset |

### Built-in WezTerm keys (no config needed)

| Key                | Action                                                              |
| ------------------ | ------------------------------------------------------------------- |
| `Ctrl+Shift+Space` | **QuickSelect** — label-jump to copy any path / URL / git hash, no mouse |
| `Ctrl+Shift+P`     | **Command palette** — fuzzy-search every WezTerm action             |
| `Ctrl+Shift+F`     | Search the scrollback                                               |

### Shell

Aliases: `ll`/`la`, `..`/`...` (defined in both `zsh/.zshrc` and
`pwsh/profile.ps1`). Directory jumping: `z <dir>` / `zi <dir>` via
[zoxide](docs/zoxide.md). Fuzzy keys on both shells: **`Ctrl+R`** history ·
**`Ctrl+T`** file path · **`Alt+C`** cd (fzf / PSFzf).

## How it fits together

- WezTerm pins the shell via `default_prog` (`pwsh` on Windows, `/usr/bin/zsh` on
  Linux), so it launches the right shell regardless of the system default — you
  get the full setup immediately. The `is_windows` branch in `wezterm.lua` is the
  only place the terminal layer diverges.
- WezTerm is also the multiplexer — panes, tabs, and splits are built in, driven
  by direct `Alt` chords in `wezterm.lua`. There's no separate multiplexer
  process to start, and the same keybinds work identically on both platforms.
- Tokyo Night is configured natively in WezTerm (built-in scheme); Neovim uses
  `folke/tokyonight.nvim` and Starship uses ANSI named colors that follow the
  terminal palette — no theme files to install.

## Customizing

| Want to…                     | Edit                                                |
| ---------------------------- | --------------------------------------------------- |
| Change font / size / opacity | `wezterm/wezterm.lua`                               |
| Change pane/tab keybinds     | the `config.keys` block in `wezterm/wezterm.lua`    |
| Change the prompt            | `starship/starship.toml` (see starship.rs/config)   |
| Change the Claude status line| `claude/statusline.js` (see [docs/claude.md](docs/claude.md)) |
| Add aliases / env            | `zsh/.zshrc` (Linux) / `pwsh/profile.ps1` (Windows) |
| Switch theme                 | `color_scheme` in WezTerm + palette in Starship     |

## Troubleshooting

- **Boxes/missing icons in the prompt** — the Nerd Font isn't active. Re-run the
  installer and set WezTerm's font to *JetBrainsMono Nerd Font*.
- **Windows-specific issues** — see [docs/windows.md](docs/windows.md)
  (ExecutionPolicy, Developer Mode, OneDrive profile path, Neovim clipboard).
- **Shell didn't change to zsh (Linux)** — run `chsh -s "$(command -v zsh)"` and
  log out/in.
