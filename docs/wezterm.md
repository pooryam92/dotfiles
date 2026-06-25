# WezTerm

[WezTerm](https://wezfurlong.org/wezterm/) is the **terminal emulator** — the
window that draws text, handles fonts/colors, and runs your shell. It's
GPU-accelerated, cross-platform (Linux, macOS, **Windows**), and configured with
a single Lua file. It's also the **multiplexer**: panes, tabs, and splits are
built in (driven by the Alt chords + `Ctrl+p`/`t`/`n`/`s` modes below), so there's no separate Zellij/tmux
layer. Everything else in this setup (your shell, Starship) runs *inside* WezTerm.

> This replaces Ghostty. WezTerm was chosen because it runs natively on **both
> Linux and Windows**, so one config file serves every machine — Ghostty has no
> official Windows build.

- Docs: <https://wezfurlong.org/wezterm/>
- Config reference: <https://wezfurlong.org/wezterm/config/files.html>
- Your config: `wezterm/wezterm.lua` → linked to `~/.config/wezterm/wezterm.lua`
  (same path on Linux and Windows; on Windows `~` is `%USERPROFILE%`).

---

## One config, two platforms

The config is a Lua script that returns a config table. The **only** thing that
differs between Linux and Windows is the shell it launches:

```lua
local is_windows = wezterm.target_triple:find 'windows' ~= nil
config.default_prog = is_windows and { 'pwsh', '-NoLogo' } or { '/usr/bin/zsh' }
```

`target_triple` is set by WezTerm at runtime (e.g. `x86_64-pc-windows-msvc` vs
`x86_64-unknown-linux-gnu`), so the same file does the right thing everywhere.

WezTerm **auto-reloads** the file the moment you save it — no restart needed.

---

## Your config, explained

### Font

```lua
config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 11.0
```

A [Nerd Font](https://www.nerdfonts.com) is required so the glyphs/icons in
Starship render (otherwise you get tofu boxes □). The installers
(`install.sh` / `install.ps1`) install JetBrainsMono Nerd Font for this reason.

### Theme

```lua
config.color_scheme = 'Tokyo Night'
config.window_background_opacity = 1.0
```

WezTerm ships **hundreds of built-in color schemes** — no files to install.
Tokyo Night is one of them. Browse the gallery at
<https://wezfurlong.org/wezterm/colorschemes/> and just change this string.
`window_background_opacity` is `0.0`–`1.0` (`1.0` = fully opaque). Lower it
(e.g. `0.95`) if you ever want the window slightly see-through.

> Ghostty's `background-blur` had no reliable cross-platform equivalent, so it
> was dropped along with the see-through background.

### Window & cursor

```lua
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }
config.window_close_confirmation = 'NeverPrompt'  -- don't nag on close
config.default_cursor_style = 'BlinkingBar'        -- I-beam, blinking
config.hide_mouse_cursor_when_typing = true
```

### Behavior & shell

```lua
config.scrollback_lines = 100000
config.default_prog = is_windows and { 'pwsh', '-NoLogo' } or { '/usr/bin/zsh' }
```

- WezTerm copies the selection to the clipboard on mouse-up by default (the
  equivalent of Ghostty's `copy-on-select`).
- `default_prog` **forces** the shell, regardless of your system default — so you
  get the full setup immediately (pwsh on Windows, zsh on Linux).

### Keybinds — direct chords

```lua
config.keys = {
  { key = 'r', mods = 'CTRL|SHIFT', action = wezterm.action.ReloadConfiguration },
  { key = '=', mods = 'CTRL',       action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CTRL',       action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CTRL',       action = wezterm.action.ResetFontSize },
}
```

| Key            | Action            |
| -------------- | ----------------- |
| `ctrl+shift+r` | Reload config     |
| `ctrl+=`       | Font size +1      |
| `ctrl+-`       | Font size −1      |
| `ctrl+0`       | Reset font size   |

### Multiplexing — two layers: direct chords + Zellij-style modes

There are **two ways to drive panes/tabs**, both live at once — use whichever
fits the moment:

1. **Direct chords** — the fast path for what you do constantly.
2. **Zellij-style modes** — `Ctrl+p/t/n/s` enter a *mode* (a WezTerm key table),
   exactly like Zellij. Discoverable: the active mode + its keys show in the tab
   bar, and you press a letter then `Esc`. There is no `Ctrl+a` leader.

**Direct (no prefix, no Shift):**

| Keys                         | Action                                            |
| ---------------------------- | ------------------------------------------------- |
| `Alt+\`                      | Split pane **right**                              |
| `Alt+-`                      | Split pane **down**                               |
| `Alt+x`                      | Close the focused pane                            |
| `Alt+h/j/k/l` or `Alt+←↓↑→`  | Move focus between panes                          |
| `Alt+g`                      | Build a 3-pane layout: one left, two stacked right |

Split mnemonic: `\` ≈ a vertical divider (new pane to the right); `-` ≈ a
horizontal divider (new pane below). `Alt`, not `Ctrl` — `Ctrl+h` is backspace and
`Ctrl+l` is clear-screen, so they'd be clobbered in every shell. `Alt+hjkl` /
`Alt+arrows` are otherwise unused, and arrows mean you don't have to think in vim.

**Zellij-style modes** (press `Ctrl`-key, it stays active until `Esc`):

| Enter mode | Keys inside the mode                                                       |
| ---------- | -------------------------------------------------------------------------- |
| `Ctrl+p` **pane**   | `n`/`r` split right · `d` split down · `x` close · `f` fullscreen · `h/j/k/l` (or arrows) move · `Esc`/`Enter` exit |
| `Ctrl+t` **tab**    | `n` new · `1`–`9` go to tab · `h`/`l` prev/next · `r` rename · `x` close · `Esc` exit |
| `Ctrl+n` **resize** | `h/j/k/l` or arrows resize repeatedly · `Esc`/`q` exit                     |
| `Ctrl+s` **scroll** | copy mode — vim motions · `/` search · `y` yank · `Esc` exit               |

Inside a mode, actions that *create* (split / new tab / close) exit the mode so
you can type immediately; *movement* keeps the mode up. The active mode shows on
the right of the tab bar — Zellij's mode line.

**How the modes are built** — each `Ctrl`-key activates a key table that stays up
(`one_shot=false`); a `update-right-status` handler renders the hint line. See
<https://wezterm.org/config/key-tables.html>.

```lua
{ key = 'p', mods = 'CTRL', action = act.ActivateKeyTable { name = 'pane', one_shot = false } },

config.key_tables = {
  pane = {
    -- split_and_exit wraps the action with PopKeyTable so the mode closes after
    { key = 'n', action = split_and_exit(act.SplitHorizontal { domain = 'CurrentPaneDomain' }) },
    { key = 'h', action = act.ActivatePaneDirection 'Left' },   -- movement stays
    { key = 'Escape', action = 'PopKeyTable' },
    -- …
  },
}
```

Note: the lowercase `Ctrl+p/t/n/s` are distinct from WezTerm's default
`Ctrl+Shift+P/T/N` (command palette / new tab / new window), which still work.
Two cues mark the focused pane — the closest WezTerm gets to Zellij's framed
panes, since it has [no native per-pane title bar](https://github.com/wezterm/wezterm/issues/297):
inactive panes are dimmed (`config.inactive_pane_hsb`), and the split lines
between panes are coloured Tokyo Night blue (`config.colors.split`) so the
boundaries read as visible borders.

> **Coming from Zellij?** This recreates Zellij's modal `Ctrl+p`/`Ctrl+t`/`Ctrl+n`
> scheme. The one thing it can't bring back is detach/reattach — closing the window
> ends its sessions. That was a deliberate trade (you rarely used it) for one fewer
> tool and identical keybinds on both OSes.

> **Want seamless Neovim ↔ WezTerm splits?** [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim)
> makes one set of `Ctrl+hjkl` keys cross both WezTerm panes *and* Neovim splits.
> It's a Neovim plugin (so a dependency), must not be lazy-loaded, and pane
> *resize* across the boundary needs a recent WezTerm. Not wired up here yet.

---

## Day-to-day usage

- **Editing the config:** just save — WezTerm hot-reloads. `ctrl+shift+r` forces it.
- **Check for config errors:** run `wezterm` from another terminal, or open the
  debug overlay with `ctrl+shift+l` — config errors show there.
- **List color schemes:** <https://wezfurlong.org/wezterm/colorschemes/> or
  `wezterm ls-fonts` for font diagnostics.
- Because copy-on-select is on, **select text to copy**; paste with
  `ctrl+shift+v`.
- **Panes/tabs:** `Alt+\` / `Alt+-` to split, `Alt+x` to close, `Alt+h/j/k/l` (or `Alt+arrows`) to
  move between panes, `Alt+g` for the 3-pane layout, `Ctrl+t` then `n` for a new
  tab. See the keybind tables above.

### Built-in keys worth knowing (no config needed)

These ship with WezTerm and aren't redefined here, so they work out of the box —
the keyboard wins most people miss:

| Key                | Action                                                                 |
| ------------------ | ---------------------------------------------------------------------- |
| `Ctrl+Shift+Space` | **QuickSelect** — labels every path, URL, and git hash on screen; type the label to copy it, no mouse. Perfect for yanking a file path out of a stack trace or a commit hash out of `git log`. |
| `Ctrl+Shift+P`     | **Command palette** — fuzzy-search every WezTerm action by name.       |
| `Ctrl+Shift+F`     | Search the scrollback (then `Enter`/`n`/`p` to walk matches).          |
| `Ctrl+Shift+V`     | Paste from the clipboard.                                              |

(`Ctrl+s` here also opens copy mode — the same scrollback/search vim-motion mode.)

---

## Common tweaks

**Fully opaque:**
```lua
config.window_background_opacity = 1.0
```

**Switch theme:**
```lua
config.color_scheme = 'Tokyo Night Storm'
```

**Light/dark by system appearance:**
```lua
local function scheme_for(appearance)
  if appearance:find 'Dark' then return 'Tokyo Night' else return 'Tokyo Night Day' end
end
config.color_scheme = scheme_for(wezterm.gui.get_appearance())
```

**Change a mode-entry key** (e.g. use `Ctrl+b` instead of `Ctrl+p` for pane mode):
```lua
{ key = 'b', mods = 'CTRL', action = act.ActivateKeyTable { name = 'pane', one_shot = false } },
```

**Confirm before closing a pane** (default closes immediately) — in the `pane`
key table, swap the `x` entry's `confirm = false` for `true`:
```lua
{ key = 'x', action = split_and_exit(act.CloseCurrentPane { confirm = true }) },
```

**Tweak the `Alt+g` layout** — edit the `action_callback`: `pane:split` directions
and `size` fractions decide the arrangement (e.g. add a third `:split` for 4 panes).

---

## Troubleshooting

- **Tofu boxes (□) instead of icons** — the Nerd Font isn't active. Confirm
  `config.font` is exactly `JetBrainsMono Nerd Font` and that the font is
  installed (re-run the installer; on Linux `fc-cache -f`).
- **Config change did nothing** — there's a Lua error. Run `wezterm` from a
  different terminal to see the error, or check the debug overlay
  (`ctrl+shift+l`).
- **Wrong shell launches** — check the `default_prog` branch; on Windows `pwsh`
  must be on `PATH` (installed by `install.ps1`).
