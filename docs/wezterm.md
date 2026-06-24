# WezTerm

[WezTerm](https://wezfurlong.org/wezterm/) is the **terminal emulator** — the
window that draws text, handles fonts/colors, and runs your shell. It's
GPU-accelerated, cross-platform (Linux, macOS, **Windows**), and configured with
a single Lua file. Everything else in this setup (your shell, Zellij, Starship)
runs *inside* WezTerm.

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
config.font_size = 12.0
```

A [Nerd Font](https://www.nerdfonts.com) is required so the glyphs/icons in
Starship and Zellij render (otherwise you get tofu boxes □). The installers
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

### Keybinds

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

---

## Day-to-day usage

- **Editing the config:** just save — WezTerm hot-reloads. `ctrl+shift+r` forces it.
- **Check for config errors:** run `wezterm` from another terminal, or open the
  debug overlay with `ctrl+shift+l` — config errors show there.
- **List color schemes:** <https://wezfurlong.org/wezterm/colorschemes/> or
  `wezterm ls-fonts` for font diagnostics.
- Because copy-on-select is on, **select text to copy**; paste with
  `ctrl+shift+v`.

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

**Native splits** (WezTerm has its own panes, independent of Zellij):
```lua
-- ctrl+shift+arrows to move; alt+enter to split — see the keys table.
```
> In this setup Zellij handles splitting/tabs inside the terminal, so you
> usually won't need WezTerm's own splits — but they exist if you want them.

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
