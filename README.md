# dotfiles

A clean terminal environment for **Linux** (Pop!_OS / Ubuntu) **and Windows**,
themed Tokyo Night end to end. One repo, two platforms — the same configs
are shared across both; only the shell differs (zsh on Linux, PowerShell on
Windows).

| Layer        | Tool                                              |
| ------------ | ------------------------------------------------- |
| Terminal     | [WezTerm](https://wezfurlong.org/wezterm/) — runs natively on Linux & Windows; also the multiplexer (built-in panes/tabs/splits) |
| Shell        | zsh (Linux) / [PowerShell 7](https://learn.microsoft.com/powershell/) (Windows) |
| Prompt       | native prompt functions on **both** shells — same layout/colors, zero subprocesses per draw (path + git branch + red-on-error `>`) |
| Navigation   | [zoxide](https://github.com/ajeetdsouza/zoxide) — smarter `cd` (`z`/`zi`) |
| Search       | [fzf](https://github.com/junegunn/fzf) (fuzzy picker: `Ctrl+R/T`, `Alt+C`) + [fd](https://github.com/sharkdp/fd) (fast `find`) + [ripgrep](https://github.com/BurntSushi/ripgrep) (search file contents) + [bat](https://github.com/sharkdp/bat) (previews) |
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

- [WezTerm](wezterm/README.md) — the terminal *and* multiplexer: fonts, themes, panes/tabs, the OS branch
- [zsh](zsh/README.md) — the shell: history, completion, plugins, aliases
- [Shell line editing](docs/shell-editing.md) — the shared emacs-style editing keys (same on zsh & PowerShell) + `Ctrl+X Ctrl+E` to edit in nvim
- [fzf + fd + rg + bat](docs/fzf.md) — fuzzy finding: `Ctrl+R` history, `Ctrl+T` files (with previews), `Alt+C` cd, `rg` content search
- [zoxide](docs/zoxide.md) — smarter `cd`: jump to frecent dirs with `z`/`zi`
- [Neovim](nvim/README.md) — minimal single-file config: sensible defaults, keymaps, Tokyo Night
- [Zed](zed/README.md) — the GUI editor: Vim mode, JetBrains Islands Dark theme, fonts, keymap (**opt-in install**: `zed/install-zed.{sh,ps1}`)
- [IdeaVim](intellij/README.md) — Vim in JetBrains IDEs: leader maps, IDE actions
- [Claude Code](claude/README.md) — the AI agent: themed status line, synced settings
- [COSMIC on niri](niri/README.md) — **opt-in, Linux-only**: COSMIC's shell on a scrollable-tiling compositor (`niri/install-cosmic-niri.sh`)
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

Then open a fresh **WezTerm** window — it launches your shell with the same fast
native prompt on both OSes. Split with `Alt+\` / `Alt+-`, hop panes
with `Alt+h/j/k/l` (see [Keybindings](#keybindings) for the full set).

## What the installers do

Both are **idempotent** — safe to re-run. Anything already at a target path is
backed up to `<file>.bak.<timestamp>` before linking.

**`install.sh` (Linux)** installs apt packages (`zsh`, `git`, `fzf`, `fd`,
`ripgrep`, `bat`, plugins, etc.), **WezTerm** (nightly .deb), and **zoxide**,
**Neovim**, and **Claude Code** (official installers) as user binaries in
`~/.local/bin`. It installs the **JetBrainsMono Nerd Font**, symlinks the configs
(including Zed's), and sets **zsh** as the login shell (`chsh`). Steps using
`sudo` will prompt for your password.

**`install.ps1` (Windows)** uses [scoop](https://scoop.sh) (user-scope, no admin)
to install **PowerShell 7**, **WezTerm**, **zoxide**, **Neovim**, **fd**,
**ripgrep**, **bat**, plus `fzf` (fuzzy finder) and `win32yank` (Neovim's
clipboard), and the Nerd Font. It also installs **Claude Code** (its own native
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
`install.sh`/`install.ps1` with no argument skips anything already present and never
upgrades it. To bump the tools to their latest releases, the installer doubles as the
updater via subcommands:

```bash
./install.sh check      # Linux: list ONLY what's behind (exit 1 if any); no changes
./install.sh versions   # Linux: full installed-vs-latest table; no changes, no sudo
./install.sh update     # Linux: preview → confirm → upgrade → summary of what moved
```

```powershell
.\install.ps1 check     # Windows: list what's behind via `scoop status`; no changes
.\install.ps1 versions  # Windows: full installed list (`scoop list`); no changes
.\install.ps1 update    # Windows: preview → confirm → upgrade everything
```

`check` answers "what needs updating?" at a glance. A plain `update` first **shows
you the jump** (`zoxide 0.9.6 → 0.9.8`) with a **release-notes link** for each
tool, flags **major / 0.x-minor bumps with ⚠** (the ones most likely to break
something), and asks before changing anything — so you can read the changelog
first. Afterwards it prints a summary of exactly what moved.

These track *latest* rather than pinning versions (goal: stay simple) — the preview
lets you eyeball drift and breaking changes first. WezTerm tracks the **nightly**
channel on both OSes (upstream hasn't tagged a release since 2024; nightly is the
maintained one). Claude Code self-updates on its own (as does Zed, installed
separately); Neovim's plugins update from inside nvim with `:lua vim.pack.update()`.

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

Both shells use **emacs-style line editing** (always-on keys, no modes) — same
bindings on zsh and PowerShell: `Ctrl+A`/`Ctrl+E` (line start/end), `Ctrl+W` (kill
word), `Alt+.` (last arg), and **`Ctrl+X Ctrl+E`** to edit the command in nvim. Full
list: [docs/shell-editing.md](docs/shell-editing.md).

Aliases: `ll`/`la`, `..`/`...` (defined in both `zsh/.zshrc` and
`pwsh/profile.ps1`). Directory jumping: `z <dir>` / `zi <dir>` via
[zoxide](docs/zoxide.md). Fuzzy keys on **both** shells: **`Ctrl+T`** insert a
file path (fd-fed, bat preview) · **`Alt+C`** fuzzy-cd · **`Ctrl+R`** history
(fzf on zsh, PSReadLine's reverse-search on pwsh). Search file contents with
`rg <pattern>`. Details: [docs/fzf.md](docs/fzf.md).

## How it fits together

- WezTerm pins the shell via `default_prog` (`pwsh` on Windows, `/usr/bin/zsh` on
  Linux), so it launches the right shell regardless of the system default — you
  get the full setup immediately. The `is_windows` branch in `wezterm.lua` is the
  only place the terminal layer diverges.
- WezTerm is also the multiplexer — panes, tabs, and splits are built in, driven
  by direct `Alt` chords in `wezterm.lua`. There's no separate multiplexer
  process to start, and the same keybinds work identically on both platforms.
- Tokyo Night is configured natively in WezTerm (built-in scheme); Neovim uses
  `folke/tokyonight.nvim`, and the shell prompts use ANSI named colors that follow
  the terminal palette — no theme files to install.

## Customizing

| Want to…                     | Edit                                                |
| ---------------------------- | --------------------------------------------------- |
| Change font / size / opacity | `wezterm/wezterm.lua`                               |
| Change pane/tab keybinds     | the `config.keys` block in `wezterm/wezterm.lua`    |
| Change the prompt            | the prompt block in `zsh/.zshrc` (Linux) / the `prompt` function in `pwsh/profile.ps1` (Windows) |
| Change the Claude status line| `claude/statusline.js` (see [claude/README.md](claude/README.md)) |
| Add aliases / env            | `zsh/.zshrc` (Linux) / `pwsh/profile.ps1` (Windows) |
| Switch theme                 | `color_scheme` in WezTerm (prompts follow the terminal palette) |

## Troubleshooting

- **Boxes/missing icons in the prompt** — the Nerd Font isn't active. Re-run the
  installer and set WezTerm's font to *JetBrainsMono Nerd Font*.
- **Windows-specific issues** — see [docs/windows.md](docs/windows.md)
  (ExecutionPolicy, Developer Mode, OneDrive profile path, Neovim clipboard).
- **Shell didn't change to zsh (Linux)** — run `chsh -s "$(command -v zsh)"` and
  log out/in.
