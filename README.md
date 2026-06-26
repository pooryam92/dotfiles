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
| Self-insight | [keymap](docs/keymap.md) — usage heatmap from your shell history + a `/keymap` agent that proposes config tweaks |

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
- [Zed](docs/zed.md) — the GUI editor: Vim mode, JetBrains Islands Dark theme, fonts, keymap
- [IdeaVim](docs/ideavim.md) — Vim in JetBrains IDEs: leader maps, IDE actions
- [Claude Code](docs/claude.md) — the AI agent: themed status line, synced settings
- [cheat](docs/cheat.md) — learn-the-terminal sheet: a vim-navigable Textual TUI, lessons & search
- [keymap](docs/keymap.md) — usage heatmap from your shell history, plus the `/keymap` agent that turns it into config tweaks
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
prompt. Split with `Alt+\` / `Alt+-`, hop panes with `Alt+h/j/k/l`, or use the
Zellij-style `Ctrl+p`/`Ctrl+t` modes (see below).

## What the installers do

Both are **idempotent** — safe to re-run. Anything already at a target path is
backed up to `<file>.bak.<timestamp>` before linking.

**`install.sh` (Linux)** installs apt packages (`zsh`, `git`, `fzf`, plugins,
etc.), **WezTerm** (official Fury apt repo), and **Starship**, **zoxide**,
**Neovim**, **Zed**, and **Claude Code** (official installers) as user binaries in
`~/.local/bin`. It installs the **JetBrainsMono Nerd Font**, builds a small Python
venv (Textual) for the [`cheat`](docs/cheat.md) tool, symlinks the configs, and
sets **zsh** as the login shell (`chsh`). Steps using `sudo` will prompt for your
password.

**`install.ps1` (Windows)** uses [scoop](https://scoop.sh) (user-scope, no admin)
to install **PowerShell 7**, **WezTerm**, **Starship**, **zoxide**, **Neovim**,
**Zed**, plus `fzf` (fuzzy finder) and `win32yank` (Neovim's clipboard), the Nerd
Font, and the **PSFzf** module. It also installs **Claude Code** (its own native
installer, not scoop) and **Python** (for the [`cheat`](docs/cheat.md) tool, set
up with Textual in a venv), then links the configs. See
[docs/windows.md](docs/windows.md).

### Keeping things updated

The **config files** are symlinks into this repo, so `git pull` is all it takes to
update them on every machine. The **tools** are install-once, though — re-running
`install.sh`/`install.ps1` skips anything already present and never upgrades it. To
bump the tools to their latest releases, use the companion update scripts:

```bash
./update.sh check      # Linux: list ONLY what's behind (exit 1 if any); no changes
./update.sh versions   # Linux: full installed-vs-latest table; no changes, no sudo
./update.sh            # Linux: preview → confirm → upgrade → summary of what moved
```

```powershell
.\update.ps1 -Check    # Windows: list what's behind via `scoop status`; no changes
.\update.ps1 -Versions # Windows: full installed list (`scoop list`); no changes
.\update.ps1           # Windows: preview → confirm → upgrade everything
```

`check` answers "what needs updating?" at a glance. A plain `update` first **shows
you the jump** (`starship 1.25.1 → 1.26.0`) with a **release-notes link** for each
tool, flags **major / 0.x-minor bumps with ⚠** (the ones most likely to break
something), and asks before changing anything — so you can read the changelog
first. Afterwards it prints a summary of exactly what moved.

These track *latest* rather than pinning versions (goal: stay simple) — the preview
lets you eyeball drift and breaking changes first. WezTerm (Linux), Zed, and Claude
Code self-update on their own; Neovim's plugins update from inside nvim with
`:lua vim.pack.update()`.

## Layout

Most configs are **shared** between Linux and Windows and linked into place, so
edits here take effect immediately. Only the shell config differs.

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
| `claude/commands/keymap.md`      | `~/.claude/commands/keymap.md` | `%USERPROFILE%\.claude\commands\keymap.md` |
| `tools/cheat/cheat.py`           | `~/.config/cheat.py`          | `%USERPROFILE%\.config\cheat.py`        |
| `tools/cheat/cheat.tsv`          | `~/.config/cheat.tsv`         | `%USERPROFILE%\.config\cheat.tsv`       |
| `tools/cheat/cheat-index.tsv`    | `~/.config/cheat-index.tsv`   | `%USERPROFILE%\.config\cheat-index.tsv` |
| `tools/keymap/keymap.py`         | `~/.config/keymap.py`         | `%USERPROFILE%\.config\keymap.py`       |

After editing:

- **WezTerm** – auto-reloads on save (`ctrl+shift+r` forces it).
- **zsh** – `exec zsh` (or open a new shell). **PowerShell** – `. $PROFILE`.
- **Starship** – picked up on the next prompt.
- **Neovim** – restart `nvim` (plugins via `:lua vim.pack.update()`).
- **Zed** – applies settings/keymap edits on save; no reload.

## Keybindings

> **Learning the setup?** Run `cheat` in either shell. Bare `cheat` opens a
> **vim-navigable Textual TUI** — `j`/`k` move between categories, `l` reads a
> lesson, `/` searches, `q` quits. `cheat <category>` prints one **lesson** (each
> key with a short *why/tip*) and `cheat <word>` **searches** — both print once,
> handy for piping. It's implemented **once** in the `tools/cheat/` package
> (Python + Textual) so both shells just launch it. Full guide, data format, and
> how to add your own keys: **[docs/cheat.md](docs/cheat.md)**.

There are **two ways to drive panes/tabs**, side by side — use whichever fits the
moment. Fast direct chords for the things you do constantly, and Zellij-style
*modes* for everything else (discoverable: the active mode shows in the tab bar).

### Direct chords (no prefix, no Shift)

| Key                        | Action                          |
| -------------------------- | ------------------------------- |
| `alt+\`                    | Split pane **right**            |
| `alt+-`                    | Split pane **down**             |
| `alt+x`                    | Close the focused pane          |
| `alt+h/j/k/l` or `alt+←↓↑→`| Move focus between panes        |
| `alt+g`                    | Build a **3-pane layout** (one left, two stacked right) |
| `ctrl+shift+r`             | Reload config                   |
| `ctrl+=` / `ctrl+-` / `ctrl+0` | Font size up / down / reset |

> Mnemonic for splits: `\` ≈ a vertical divider (pane to the right); `-` ≈ a
> horizontal divider (pane below). `Alt`, not `Ctrl`, so `Ctrl+l` clear-screen
> and `Ctrl+h` backspace stay intact.

### Zellij-style modes

Press the `Ctrl` key to enter a mode (it stays active — the tab bar shows which);
press a letter, then `Esc` to leave. Mirrors Zellij's `Ctrl+p`/`Ctrl+t` scheme.

| Enter mode | Then…                                                            |
| ---------- | ---------------------------------------------------------------- |
| `Ctrl+p` **pane**   | `n`/`r` split right · `d` split down · `x` close · `f` fullscreen · `h/j/k/l` move · `Esc` |
| `Ctrl+t` **tab**    | `n` new · `1`–`9` go to tab · `h`/`l` prev/next · `r` rename · `x` close · `Esc` |
| `Ctrl+n` **resize** | `h/j/k/l` or arrows to resize repeatedly · `Esc` |
| `Ctrl+s` **scroll** | copy mode: vim motions · `/` search · `y` yank · `Esc` |

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
  by direct `Alt` chords plus Zellij-style `Ctrl+p`/`Ctrl+t`/`Ctrl+n` modes in
  `wezterm.lua`. There's no separate multiplexer process to start, and the same
  keybinds work identically on both platforms.
- Tokyo Night is configured natively in WezTerm (built-in scheme); Neovim uses
  `folke/tokyonight.nvim` and Starship uses ANSI named colors that follow the
  terminal palette — no theme files to install.

## Customizing

| Want to…                     | Edit                                                |
| ---------------------------- | --------------------------------------------------- |
| Change font / size / opacity | `wezterm/wezterm.lua`                               |
| Change pane/tab keybinds     | the `config.keys` / `config.key_tables` block in `wezterm/wezterm.lua` |
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
