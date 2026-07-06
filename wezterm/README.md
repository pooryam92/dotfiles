# WezTerm

[WezTerm](https://wezfurlong.org/wezterm/) is the **terminal emulator** — the
window that draws text, handles fonts/colors, and runs your shell. It's
GPU-accelerated, cross-platform (Linux, macOS, **Windows**), and configured with
a single Lua file. It's also the **multiplexer**: panes, tabs, and splits are
built in (driven by the `Alt` chords below — no modes, no leader), so there's no
separate Zellij/tmux layer. Everything else in this setup (your shell, the
prompt) runs *inside* WezTerm.

> This replaces Ghostty. WezTerm was chosen because it runs natively on **both
> Linux and Windows**, so one config file serves every machine — Ghostty has no
> official Windows build.

- Docs: <https://wezfurlong.org/wezterm/> · config reference:
  <https://wezfurlong.org/wezterm/config/files.html>
- Your config: `wezterm/wezterm.lua` → linked to `~/.config/wezterm/wezterm.lua`
  (same path on Linux and Windows; on Windows `~` is `%USERPROFILE%`).
- **The config is the documentation** — `wezterm.lua` is ~100 commented lines.
  The only per-OS fork is the shell it launches (`default_prog`); everything
  else is shared. WezTerm **auto-reloads** the file on save.

> **Version channel: nightly, on both OSes.** Upstream hasn't tagged a stable
> release since `20240203`, and that build had Wayland bugs under niri. Linux
> installs the nightly `.deb` from GitHub (`fetch_wezterm` in `setup/lib.sh`);
> Windows uses scoop's `wezterm-nightly`. `install.sh update` /
> `install.ps1 update` move both forward.

---

## Keybindings

Everything is a **direct `Alt` chord** — hold `Alt`, press the key. `Alt`, not
`Ctrl`, because `Ctrl+h` is backspace and `Ctrl+l` is clear-screen in every
shell; `Alt+<letter>` is otherwise free.

**Panes:**

| Keys                         | Action                                              |
| ---------------------------- | --------------------------------------------------- |
| `Alt+\`                      | Split pane **right**                                |
| `Alt+-`                      | Split pane **down**                                 |
| `Alt+x`                      | Close the focused pane                              |
| `Alt+z`                      | Zoom the focused pane to fill the tab (toggle)      |
| `Alt+h/j/k/l` or `Alt+←↓↑→`  | Move focus between panes                            |
| `Alt+Shift+h/j/k/l`          | Resize the focused pane (press repeatedly to nudge) |
| `Alt+Shift+[` / `Alt+Shift+]`| Rotate panes counter-clockwise / clockwise          |

**Tabs:**

| Keys              | Action                    |
| ----------------- | ------------------------- |
| `Alt+t`           | New tab                   |
| `Alt+w`           | Close tab                 |
| `Alt+[` / `Alt+]` | Previous / next tab       |
| `Alt+1`…`Alt+9`   | Jump straight to that tab |

**Scrollback & misc:**

| Keys           | Action                                                          |
| -------------- | --------------------------------------------------------------- |
| `Ctrl+s`       | Copy mode — vim motions · `/` search · `y` yank · `Esc` to exit |
| `Ctrl+Shift+r` | Reload config (it also auto-reloads on save)                    |
| `Ctrl+=` / `Ctrl+-` / `Ctrl+0` | Font size up / down / reset                     |

Split mnemonic: `\` ≈ a vertical divider (new pane to the right); `-` ≈ a
horizontal divider (new pane below). Resize is just the move keys with `Shift`.
`Ctrl+s` is safe because WezTerm grabs it before the shell sees it, so the
usual `Ctrl+s` terminal freeze never fires.

> **Why no modes?** An earlier version mirrored Zellij's modal
> `Ctrl+p`/`t`/`n`/`s` key tables on top of these chords. It was two ways to do
> the same thing, plus a key-table stack and a tab-bar status line to maintain.
> The chords alone are faster and far simpler, so the modal layer was removed.

### Built-in keys worth knowing (no config needed)

These ship with WezTerm and aren't redefined here — the keyboard wins most
people miss:

| Key                | Action                                                                 |
| ------------------ | ---------------------------------------------------------------------- |
| `Ctrl+Shift+Space` | **QuickSelect** — labels every path, URL, and git hash on screen; type the label to copy it, no mouse. Perfect for yanking a file path out of a stack trace or a commit hash out of `git log`. |
| `Ctrl+Shift+P`     | **Command palette** — fuzzy-search every WezTerm action by name.       |
| `Ctrl+Shift+F`     | Search the scrollback (then `Enter`/`n`/`p` to walk matches).          |
| `Ctrl+Shift+V`     | Paste from the clipboard.                                              |

Copy-on-select is WezTerm's default: **select text to copy**, `Ctrl+Shift+V`
to paste.

---

## Day-to-day usage

- **Editing the config:** just save — WezTerm hot-reloads. If a change did
  nothing, there's a Lua error: run `wezterm` from another terminal or open the
  debug overlay (`Ctrl+Shift+L`) to see it.
- **Switch theme:** set `config.color_scheme` — WezTerm ships hundreds of
  schemes built in; browse <https://wezfurlong.org/wezterm/colorschemes/>.
- **Font diagnostics:** `wezterm ls-fonts`.

> **Want seamless Neovim ↔ WezTerm splits?** [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim)
> makes one set of `Ctrl+hjkl` keys cross both WezTerm panes *and* Neovim
> splits. It's a Neovim plugin (a dependency, must not be lazy-loaded); resize
> across the boundary needs a recent WezTerm (nightly qualifies). Not wired up
> here yet.

---

## Troubleshooting

- **Tofu boxes (□) instead of icons** — the Nerd Font isn't active. Confirm
  `config.font` is exactly `JetBrainsMono Nerd Font` and that the font is
  installed (re-run the installer; on Linux `fc-cache -f`).
- **Config change did nothing** — there's a Lua error. Run `wezterm` from a
  different terminal to see it, or check the debug overlay (`Ctrl+Shift+L`).
- **Wrong shell launches** — check the `default_prog` branch; on Windows `pwsh`
  must be on `PATH` (installed by `install.ps1`).
