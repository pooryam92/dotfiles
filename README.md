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

- [WezTerm](wezterm/README.md) — the terminal *and* multiplexer: the pane/tab keybinds, built-in keys, troubleshooting
- [zsh](zsh/README.md) — the shell: what's where, common tweaks (the commented `.zshrc` is the real guide)
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
with `Alt+h/j/k/l` (see the [Cheat sheet](#cheat-sheet) for the full set).

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
upgrades it. To bump everything to its latest release:

```bash
./install.sh update     # Linux: apt upgrade + re-fetch the GitHub-release tools
```

```powershell
.\install.ps1 update    # Windows: scoop update for the managed apps
```

There's no version bookkeeping — apt/scoop and the release downloads always fetch
latest, so `update` just re-runs them and the package manager prints what moved.
WezTerm tracks the **nightly** channel on both OSes (upstream hasn't tagged a release
since 2024; nightly is the maintained one). Claude Code self-updates on its own (as
does Zed, installed separately); Neovim's plugins update from inside nvim with
`:lua vim.pack.update()`.

## Layout

Most configs are **shared** between Linux and Windows and linked into place, so
edits here take effect immediately. Only the shell config differs.

The setup machinery lives in **`setup/`**: the link targets below are data in
[`setup/links.tsv`](setup/links.tsv), read by the shared helpers in
`setup/lib.sh` / `setup/lib.ps1`. Adding a config is one `links.tsv` row; adding
a tool is one `install_*` call in `install.sh` (Linux) and/or a `$SCOOP_APPS`
entry in `setup/lib.ps1` (Windows). Only `install.sh` / `install.ps1` stay at
the repo root as the entry points.

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

## Cheat sheet

The keys and commands that drive this setup **every day** — same on Linux and
Windows unless noted. This is a curated subset; each block links to its canonical
full table. (App-specific editor keys — [IdeaVim](intellij/README.md),
[Zed](zed/README.md), [Neovim](nvim/README.md) — live in their own guides.)

**WezTerm — panes, tabs, terminal** · full table: [wezterm/README.md](wezterm/README.md)

Direct `Alt` chords — no prefix, no leader, no modes.

| Keys | Action |
| ---- | ------ |
| `Alt+\` / `Alt+-` | Split pane **right** / **down** |
| `Alt+h/j/k/l` | Move focus between panes |
| `Alt+Shift+h/j/k/l` | Resize the focused pane |
| `Alt+z` / `Alt+x` | **Zoom** pane (toggle) / **close** pane |
| `Alt+t` / `Alt+w` | New / close **tab** · `Alt+1`…`9` jump to tab |
| `Ctrl+s` | **Copy mode** — vim motions, `/` search, `y` yank, `Esc` out |
| `Ctrl+Shift+Space` | **QuickSelect** — label & copy any path/URL/hash on screen, no mouse |
| `Ctrl+Shift+P` | Command palette (fuzzy-search every action) |

**Shell — line editing & history** · full table: [docs/shell-editing.md](docs/shell-editing.md)

Emacs-style, always-on (no modes) — identical on zsh and PowerShell.

| Keys | Action |
| ---- | ------ |
| `Ctrl+A` / `Ctrl+E` | Jump to **start** / **end** of line |
| `Alt+B` / `Alt+F` | Move **back** / **forward** a word |
| `Ctrl+W` / `Alt+D` | Delete word **behind** / **ahead** |
| `Ctrl+U` / `Ctrl+K` | Kill **whole line** / to **end of line** |
| `Alt+.` | Insert the **last argument** of the previous command |
| `↑` / `↓` | **Prefix**-search history (type first, then ↑) |
| `Ctrl+X Ctrl+E` | Edit the current command in **nvim** |

**Finding things — fuzzy pick & search** · full table: [docs/fzf.md](docs/fzf.md)

| Keys / command | Action |
| -------------- | ------ |
| `Ctrl+R` | Fuzzy reverse-search **history** |
| `Ctrl+T` | Insert a **file path** at the cursor (bat preview) *(zsh)* |
| `Alt+C` | Fuzzy-**cd** into a subdirectory *(zsh)* |
| `rg <pattern>` | Search file **contents** (skips `.gitignore`/`.git`) |
| `fd <fragment>` | Find **files by name** |

**Getting around — jump & aliases** · full table: [docs/zoxide.md](docs/zoxide.md)

| Command | Action |
| ------- | ------ |
| `z <frag>` | Jump to the most **frecent** dir matching `frag` |
| `zi <frag>` | Interactive pick from matches (fzf) |
| `z -` | Previous directory · `z` (no arg) → home |
| `ll` / `la` | `ls -lah` / `ls -A` |
| `..` / `...` | Up one / two directories |

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
