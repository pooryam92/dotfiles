# dotfiles

A clean terminal environment for **Linux** (Pop!_OS / Ubuntu) **and Windows**,
themed Catppuccin Mocha end to end. One repo, two platforms — the same configs
are shared across both; only the shell differs (zsh on Linux, PowerShell on
Windows).

| Layer        | Tool                                              |
| ------------ | ------------------------------------------------- |
| Terminal     | [WezTerm](https://wezfurlong.org/wezterm/) — runs natively on Linux & Windows |
| Multiplexer  | [Zellij](https://zellij.dev) — native Windows support since v0.44 |
| Shell        | zsh (Linux) / [PowerShell 7](https://learn.microsoft.com/powershell/) (Windows) |
| Prompt       | [Starship](https://starship.rs)                   |
| Editor       | [Neovim](https://neovim.io) (kickstart-based, + Markdown rendering) |
| IDE editing  | [IdeaVim](https://github.com/JetBrains/ideavim) — Vim plugin for JetBrains IDEs (`.ideavimrc`) |

> **Why WezTerm instead of Ghostty?** Ghostty has no official Windows build, so
> the terminal layer would fork across machines. WezTerm is cross-platform and
> Lua-configured, so a single `wezterm.lua` serves every OS.

## Learn it

In-depth, beginner-friendly guides to using and configuring each tool — grounded
in the actual config in this repo:

- [WezTerm](docs/wezterm.md) — the terminal: fonts, themes, keybinds, the OS branch
- [Zellij](docs/zellij.md) — the multiplexer: panes, tabs, sessions, modes
- [zsh](docs/zsh.md) — the shell: history, completion, plugins, aliases
- [Starship](docs/starship.md) — the prompt: modules, format, styling
- [Neovim](docs/nvim.md) — kickstart-based config: plugins, markdown rendering, keymaps
- [IdeaVim](docs/ideavim.md) — Vim in JetBrains IDEs: leader maps, IDE actions
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

Then open a fresh **WezTerm** window — it launches your shell, auto-starts
Zellij, and shows the Starship prompt.

## What the installers do

Both are **idempotent** — safe to re-run. Anything already at a target path is
backed up to `<file>.bak.<timestamp>` before linking.

**`install.sh` (Linux)** installs apt packages (`zsh`, `git`, plugins, etc.),
**WezTerm** (official Fury apt repo), and **Zellij**, **Starship**, **Neovim**,
and the **tree-sitter CLI** as user binaries in `~/.local/bin`. It installs the
**JetBrainsMono Nerd Font**, symlinks the configs, and sets **zsh** as the login
shell (`chsh`). Steps using `sudo` will prompt for your password.

**`install.ps1` (Windows)** uses [scoop](https://scoop.sh) (user-scope, no admin)
to install **PowerShell 7**, **WezTerm**, **Zellij**, **Starship**, **Neovim**,
plus `zig` / `ripgrep` / `fd` / `fzf` / `win32yank` (Neovim's deps) and the Nerd
Font, then links the configs. See [docs/windows.md](docs/windows.md).

## Layout

Most configs are **shared** between Linux and Windows and linked into place, so
edits here take effect immediately. Only the shell config differs.

| Repo file                | Linux target                  | Windows target                          |
| ------------------------ | ----------------------------- | --------------------------------------- |
| `wezterm/wezterm.lua`    | `~/.config/wezterm/wezterm.lua` | `%USERPROFILE%\.config\wezterm\wezterm.lua` |
| `zellij/config.kdl`      | `~/.config/zellij/config.kdl` | `%APPDATA%\zellij\config.kdl`           |
| `starship/starship.toml` | `~/.config/starship.toml`     | `%USERPROFILE%\.config\starship.toml`   |
| `nvim/`                  | `~/.config/nvim`              | `%LOCALAPPDATA%\nvim` (junction)        |
| `intellij/.ideavimrc`    | `~/.ideavimrc`                | `%USERPROFILE%\.ideavimrc`              |
| `zsh/.zshrc`             | `~/.zshrc`                    | —                                       |
| `pwsh/profile.ps1`       | —                             | `$PROFILE.CurrentUserAllHosts`          |

After editing:

- **WezTerm** – auto-reloads on save (`ctrl+shift+r` forces it).
- **zsh** – `exec zsh` (or open a new shell). **PowerShell** – `. $PROFILE`.
- **Zellij** – restart the session, or `Ctrl+o` → `w` to switch.
- **Starship** – picked up on the next prompt.
- **Neovim** – restart `nvim` (plugins via `:lua vim.pack.update()`).

## Keybindings

### WezTerm

| Key            | Action              |
| -------------- | ------------------- |
| `ctrl+shift+r` | Reload config       |
| `ctrl+=`       | Increase font size  |
| `ctrl+-`       | Decrease font size  |
| `ctrl+0`       | Reset font size     |

### Zellij (defaults)

| Key       | Mode / Action          |
| --------- | ---------------------- |
| `Ctrl+p`  | Pane mode              |
| `Ctrl+t`  | Tab mode               |
| `Ctrl+n`  | Resize mode            |
| `Ctrl+s`  | Scroll / search mode   |
| `Ctrl+o`  | Session mode           |
| `Ctrl+q`  | Quit                   |

Shell aliases: `zj` → `zellij`, `ll`/`la`, `..`/`...` (defined in both
`zsh/.zshrc` and `pwsh/profile.ps1`).

## How it fits together

- WezTerm pins the shell via `default_prog` (`pwsh` on Windows, `/usr/bin/zsh` on
  Linux), so it launches the right shell regardless of the system default — you
  get the full setup immediately. The `is_windows` branch in `wezterm.lua` is the
  only place the terminal layer diverges.
- The shell auto-starts Zellij **only inside WezTerm** (guarded by
  `$WEZTERM_PANE`), so SSH sessions, other terminals, and IDE shells stay plain.
  This guard lives at the bottom of `zsh/.zshrc` and `pwsh/profile.ps1`.
- Catppuccin Mocha is configured natively in WezTerm (built-in scheme), Zellij,
  and Starship — no theme files to install.
- Zellij's `config.kdl` is OS-agnostic: it omits `default_shell` (inherits the
  shell WezTerm launched) and `copy_command` (uses the terminal's OSC52
  clipboard), so one file works on both platforms.

## Customizing

| Want to…                     | Edit                                                |
| ---------------------------- | --------------------------------------------------- |
| Change font / size / opacity | `wezterm/wezterm.lua`                               |
| Disable Zellij auto-start    | remove the last block in `zsh/.zshrc` / `pwsh/profile.ps1` |
| Change the prompt            | `starship/starship.toml` (see starship.rs/config)   |
| Add aliases / env            | `zsh/.zshrc` (Linux) / `pwsh/profile.ps1` (Windows) |
| Switch theme                 | `color_scheme` in WezTerm + `theme` in Zellij + palette in Starship |

## Troubleshooting

- **Boxes/missing icons in the prompt** — the Nerd Font isn't active. Re-run the
  installer and set WezTerm's font to *JetBrainsMono Nerd Font*.
- **Clipboard copy doesn't work in Zellij** — copy goes through the terminal's
  OSC52 clipboard. If it fails, set a `copy_command` in `zellij/config.kdl`:
  `wl-copy` (Wayland), `xclip -selection clipboard` (X11), or `clip` (Windows).
- **Windows-specific issues** — see [docs/windows.md](docs/windows.md)
  (ExecutionPolicy, Developer Mode, OneDrive profile path, Neovim deps).
- **Shell didn't change to zsh (Linux)** — run `chsh -s "$(command -v zsh)"` and
  log out/in.
