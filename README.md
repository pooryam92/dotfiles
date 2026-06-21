# dotfiles

A clean terminal environment for **Pop!_OS / Ubuntu**, themed Catppuccin Mocha
end to end.

| Layer        | Tool                                              |
| ------------ | ------------------------------------------------- |
| Terminal     | [Ghostty](https://ghostty.org)                    |
| Multiplexer  | [Zellij](https://zellij.dev)                      |
| Shell        | zsh (+ autosuggestions, syntax-highlighting)      |
| Prompt       | [Starship](https://starship.rs)                   |
| Editor       | [Neovim](https://neovim.io) (kickstart-based, + Markdown rendering) |
| IDE editing  | [IdeaVim](https://github.com/JetBrains/ideavim) — Vim plugin for JetBrains IDEs (`.ideavimrc`) |

## Learn it

In-depth, beginner-friendly guides to using and configuring each tool — grounded
in the actual config in this repo:

- [Ghostty](docs/ghostty.md) — the terminal: fonts, themes, keybinds, config
- [Zellij](docs/zellij.md) — the multiplexer: panes, tabs, sessions, modes
- [zsh](docs/zsh.md) — the shell: history, completion, plugins, aliases
- [Starship](docs/starship.md) — the prompt: modules, format, styling
- [Neovim](docs/nvim.md) — kickstart-based config: plugins, markdown rendering, keymaps
- [IdeaVim](docs/ideavim.md) — Vim in JetBrains IDEs: leader maps, IDE actions

## Quick start

```sh
git clone https://github.com/pooryam92/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

Then open a fresh Ghostty window — it lands you in zsh, auto-starts Zellij, and
shows the Starship prompt.

## What `install.sh` does

1. Installs apt packages: `zsh`, `git`, `curl`, `unzip`, `ca-certificates`,
   `fontconfig`, `wl-clipboard`, `zsh-autosuggestions`, `zsh-syntax-highlighting`.
2. Installs **Ghostty** from the
   [ghostty-ubuntu](https://github.com/mkasberg/ghostty-ubuntu) `.deb` matching
   your Ubuntu version + architecture.
3. Installs **Zellij**, **Starship**, and **Neovim** as user binaries in
   `~/.local/bin` (Neovim's latest stable — apt's is too old for the config).
4. Installs the **JetBrainsMono Nerd Font** (for prompt/multiplexer glyphs).
5. Symlinks the configs (see [Layout](#layout)).
6. Sets **zsh** as the default login shell (`chsh`).

It is **idempotent** — safe to re-run. Anything already at a target path is
backed up to `<file>.bak.<timestamp>` before linking. Steps 1 and 6 use `sudo`
and will prompt for your password.

> Requires Ubuntu/Pop with `apt`. Tested on `x86_64` (`amd64`); the binary
> installs also handle `arm64`.

## Layout

Configs live in this repo and are symlinked into place, so edits here take
effect immediately:

```
ghostty/config           ->  ~/.config/ghostty/config
zellij/config.kdl        ->  ~/.config/zellij/config.kdl
starship/starship.toml   ->  ~/.config/starship.toml
zsh/.zshrc               ->  ~/.zshrc
intellij/.ideavimrc      ->  ~/.ideavimrc
nvim/                    ->  ~/.config/nvim
```

After editing:

- **Ghostty** – `ctrl+shift+r` to reload.
- **zsh** – `exec zsh` (or open a new shell).
- **Zellij** – restart the session, or `Ctrl+o` → `w` to switch.
- **Starship** – picked up on the next prompt.
- **Neovim** – restart `nvim` (plugins via `:lua vim.pack.update()`).

## Keybindings

### Ghostty

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

Aliases in zsh: `zj` → `zellij`, `ll`/`la`, `..`/`...`.

## How it fits together

- Ghostty pins `command = /usr/bin/zsh`, so it launches zsh regardless of the
  desktop session's `$SHELL` (which only refreshes on re-login) — you get the
  full setup immediately, even before the `chsh` from step 6 takes effect.
- zsh auto-starts Zellij **only inside Ghostty** (guarded by
  `$GHOSTTY_RESOURCES_DIR`), so SSH sessions, other terminals, and IDE shells
  stay plain. Set/unset this in the bottom block of `zsh/.zshrc`.
- Catppuccin Mocha is configured natively in Ghostty, Zellij, and Starship —
  no theme files to install.

## Customizing

| Want to…                     | Edit                                                |
| ---------------------------- | --------------------------------------------------- |
| Change font / size / opacity | `ghostty/config`                                    |
| Disable Zellij auto-start    | remove the last block in `zsh/.zshrc`               |
| Change the prompt            | `starship/starship.toml` (see starship.rs/config)   |
| Add aliases / env            | `zsh/.zshrc`                                         |
| Switch theme                 | `theme =` in Ghostty + `theme` in Zellij + palette in Starship |

## Troubleshooting

- **Boxes/missing icons in the prompt** — the Nerd Font isn't active. Re-run
  `install.sh` (or `fc-cache -f`) and set Ghostty's font to *JetBrainsMono Nerd Font*.
- **Clipboard copy doesn't work in Zellij** — on X11 change `copy_command` in
  `zellij/config.kdl` to `xclip -selection clipboard` (install `xclip`).
- **No Ghostty `.deb` for your release** — install from
  [ghostty.org/docs/install](https://ghostty.org/docs/install); the rest of the
  setup is unaffected.
- **Shell didn't change to zsh** — run `chsh -s "$(command -v zsh)"` and log out/in.
