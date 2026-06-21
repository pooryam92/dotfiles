# Ghostty

[Ghostty](https://ghostty.org) is the **terminal emulator** — the window that
draws text, handles fonts/colors, and runs your shell. It's GPU-accelerated and
configured with a single plain-text file. Everything else in this setup (zsh,
Zellij, Starship) runs *inside* Ghostty.

- Docs: <https://ghostty.org/docs>
- Config reference: <https://ghostty.org/docs/config/reference>
- Your config: `ghostty/config` → symlinked to `~/.config/ghostty/config`

---

## Your config, explained

The config format is just `key = value`, one per line. `#` starts a comment.

### Font

```ini
font-family = "JetBrainsMono Nerd Font"
font-size = 12
```

- `font-family` — a [Nerd Font](https://www.nerdfonts.com) is required so the
  glyphs/icons in Starship and Zellij render (otherwise you get tofu boxes □).
  `install.sh` installs JetBrainsMono Nerd Font for exactly this reason.
- `font-size` — point size. You can also change it live with the keybinds below
  (those changes are temporary; this sets the startup default).

### Theme

```ini
theme = Catppuccin Mocha
background-opacity = 0.95
background-blur = true
```

- `theme` — Ghostty ships with hundreds of built-in themes, **no files to
  install**. List them with `ghostty +list-themes` (a live preview picker) and
  just change this line to switch.
- `background-opacity` — `0.0`–`1.0`. `0.95` = slightly see-through.
- `background-blur` — blurs whatever is behind the transparent background
  (compositor-dependent; works on Pop!_OS COSMIC / GNOME).

### Window

```ini
window-padding-x = 10
window-padding-y = 10
window-padding-balance = true
window-theme = ghostty
```

- `window-padding-x/y` — breathing room (px) between text and the window edge.
- `window-padding-balance` — distributes leftover padding evenly so text stays
  centered instead of all the slack ending up on one side.
- `window-theme` — whether the title bar / window chrome follows the Ghostty
  theme (`ghostty`), the system (`system`), or is forced `light`/`dark`.

### Cursor

```ini
cursor-style = bar
cursor-style-blink = true
mouse-hide-while-typing = true
```

- `cursor-style` — `bar` (I-beam), `block`, or `underline`.
- `mouse-hide-while-typing` — hides the mouse pointer while you type so it
  doesn't sit over text.

### Behavior

```ini
scrollback-limit = 100000
copy-on-select = clipboard
confirm-close-surface = false
shell-integration = zsh
command = /usr/bin/zsh
```

- `scrollback-limit` — bytes of history kept per surface for scrolling back.
- `copy-on-select = clipboard` — selecting text with the mouse copies it
  straight to the system clipboard (no Ctrl+C needed).
- `confirm-close-surface = false` — don't nag with a confirmation dialog when
  closing a pane/window.
- `shell-integration = zsh` — enables Ghostty's shell integration features
  (working-dir tracking for new tabs, prompt marking, etc.).
- `command = /usr/bin/zsh` — **forces** Ghostty to launch zsh, regardless of
  what your login `$SHELL` is. This is why you get the full setup immediately,
  even before `chsh` (from `install.sh`) takes effect on next login.

### Keybinds

```ini
keybind = ctrl+shift+r=reload_config
keybind = ctrl+equal=increase_font_size:1
keybind = ctrl+minus=decrease_font_size:1
keybind = ctrl+zero=reset_font_size
```

Syntax is `keybind = <trigger>=<action>[:argument]`. The `:1` on font size is
the step (1 point per press).

| Key            | Action            |
| -------------- | ----------------- |
| `ctrl+shift+r` | Reload config     |
| `ctrl+=`       | Font size +1      |
| `ctrl+-`       | Font size −1      |
| `ctrl+0`       | Reset font size   |

---

## Day-to-day usage

- **Reload after editing the config:** `ctrl+shift+r` (no restart needed).
- **Validate / inspect config:** `ghostty +show-config` prints the *effective*
  config (your file merged with defaults) — great for spotting typos.
- **Browse themes live:** `ghostty +list-themes`.
- **List every valid option:** `ghostty +show-config --default --docs` dumps all
  keys with inline documentation.
- Because `copy-on-select` is on, just **select text to copy**; paste with
  `ctrl+shift+v` (or middle-click).

---

## Common tweaks

**Make it fully opaque:**
```ini
background-opacity = 1.0
```

**Switch theme** (try one, then keep it):
```ini
theme = catppuccin-frappe
```

**Split panes** (Ghostty has native splits, independent of Zellij):
```ini
keybind = ctrl+shift+e=new_split:right
keybind = ctrl+shift+o=new_split:down
keybind = ctrl+shift+h=goto_split:left
keybind = ctrl+shift+l=goto_split:right
```
> Note: in this setup Zellij handles splitting/tabs inside the terminal, so you
> usually won't need Ghostty's own splits — but they exist if you want them.

**Different theme for light vs dark system mode:**
```ini
theme = dark:Catppuccin Mocha,light:Catppuccin Latte
```

**Set a default window size (columns × rows):**
```ini
window-width = 120
window-height = 34
```

After any change: `ctrl+shift+r` to reload.

---

## Troubleshooting

- **Tofu boxes (□) instead of icons** — the Nerd Font isn't active. Confirm
  `font-family` is exactly `JetBrainsMono Nerd Font` and re-run `install.sh`
  (or `fc-cache -f`).
- **Config change did nothing** — you edited the wrong file, or there's a syntax
  error. Run `ghostty +show-config` and check the value is what you expect.
- **No transparency/blur** — depends on your compositor; some setups need blur
  enabled at the desktop-environment level.
