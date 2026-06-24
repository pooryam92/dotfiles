# Zellij

[Zellij](https://zellij.dev) is a **terminal multiplexer** (like tmux): it runs
*inside* one WezTerm window and lets you split it into panes, manage multiple
tabs, and — crucially — keep sessions alive in the background so you can detach
and reattach later without losing your work. Since v0.44 it runs natively on
Windows too (via ConPTY).

In this setup the shell auto-starts Zellij **only inside WezTerm** (see
[zsh.md](zsh.md) / [windows.md](windows.md)), so every WezTerm window drops you
straight into a session.

- Docs: <https://zellij.dev/documentation>
- Your config: `zellij/config.kdl` → `~/.config/zellij/config.kdl` (Linux) /
  `%APPDATA%\zellij\config.kdl` (Windows)

---

## Core concepts

```
Session  ──┬── Tab 1 ──┬── Pane
           │           └── Pane
           └── Tab 2 ──── Pane
```

- **Pane** — one shell (or program) in a rectangle of the screen.
- **Tab** — a full screen of panes; switch between tabs like browser tabs.
- **Session** — the whole thing. It lives in a background server, so you can
  **detach** (leave it running) and **reattach** later — even after closing
  WezTerm.

### Modes (the most important idea)

Zellij is **modal**. You're normally in *Normal* mode (typing into your shell).
To do something to the layout, you press a `Ctrl`-key to **enter a mode**, then
press a letter for the action, then `Enter`/`Esc` to go back. The status bar at
the bottom always shows the current mode and available keys — **read it**.

| Enter with | Mode    | What you do there                          |
| ---------- | ------- | ------------------------------------------ |
| `Ctrl+p`   | Pane    | split, move between, close, fullscreen     |
| `Ctrl+t`   | Tab     | new tab, rename, move between tabs         |
| `Ctrl+n`   | Resize  | resize the focused pane                    |
| `Ctrl+s`   | Scroll  | scroll back, search the scrollback         |
| `Ctrl+o`   | Session | detach, switch session, plugin manager     |
| `Ctrl+h`   | Move    | move panes around                          |
| `Ctrl+g`   | Locked  | disable all Zellij keys (pass-through)     |
| `Ctrl+q`   | —       | quit the whole session                     |

> **Why `Ctrl+g` (Locked) matters:** if a program inside Zellij needs a key
> that Zellij intercepts (e.g. vim using `Ctrl+t`), press `Ctrl+g` to lock
> Zellij out, do your thing, then `Ctrl+g` again to unlock.

---

## Your config, explained

The config is [KDL](https://kdl.dev) — `key "value"` lines and `{ }` blocks.
`//` starts a comment.

```kdl
theme "tokyo-night-dark"
default_shell "zsh"
default_layout "compact"
```

- `theme` — Tokyo Night, built in (no file to install).
- `default_shell` — new panes open zsh.
- `default_layout "compact"` — uses the slim single-line status bar instead of
  the default two-row bar (more screen for your work). Other built-ins:
  `default`, `strider` (with a file sidebar).

```kdl
pane_frames true
mouse_mode true
copy_on_select true
copy_command "wl-copy"
show_startup_tips true
scrollback_editor "vi"
```

- `pane_frames` — draws borders around panes (shows pane title / focus).
- `mouse_mode` — click to focus panes, drag borders to resize, scroll with the
  wheel.
- `copy_on_select` — selecting text copies it automatically.
- `copy_command "wl-copy"` — **Wayland** clipboard tool (Pop!_OS COSMIC is
  Wayland). On X11 change this to `xclip -selection clipboard`.
- `show_startup_tips true` — show the tip screen when a new session starts. Set
  to `false` to skip it.
- `scrollback_editor "vi"` — in Scroll mode you can hit a key to open the whole
  scrollback in this editor for searching/copying.

```kdl
ui {
    pane_frames {
        rounded_corners true
        hide_session_name false
    }
}
```

- Cosmetic: rounded pane borders, and keep the session name shown in the frame.

---

## Day-to-day usage

A typical flow (remember: enter a mode, then press the letter):

**Split the screen:**
- `Ctrl+p` then `n` → new pane (or `r` = split right, `d` = split down)
- `Ctrl+p` then arrow keys / `h j k l` → move focus between panes
- `Ctrl+p` then `x` → close the focused pane
- `Ctrl+p` then `f` → toggle fullscreen for the focused pane

**Tabs:**
- `Ctrl+t` then `n` → new tab
- `Ctrl+t` then `r` → rename tab
- `Ctrl+t` then number → jump to that tab

**Resize:** `Ctrl+n` then arrows (then `Esc`).

**Scroll back / search:** `Ctrl+s` then `↑`/`PageUp`; press `s` to search.
`Esc` to return.

**Detach and reattach (the killer feature):**
- `Ctrl+o` then `d` → detach. Your session keeps running in the background; close
  WezTerm if you want.
- From any shell: `zellij list-sessions` (alias `zj ls` won't work — `zj` is just
  `zellij`, so `zj list-sessions`) to see them.
- `zellij attach <name>` → reattach exactly where you left off.

Because of `ZELLIJ_AUTO_ATTACH=true` in your shell config, opening a new WezTerm
window will **reattach** an existing session rather than spawning a fresh one.

---

## Common tweaks

**Switch theme:**
```kdl
theme "nord"
```

**Use the full two-row status bar instead of compact:**
```kdl
default_layout "default"
```

**On X11 instead of Wayland (clipboard):**
```kdl
copy_command "xclip -selection clipboard"
```

**Custom keybindings** — Zellij lets you remap everything in a `keybinds { }`
block. Start from the defaults: `zellij setup --dump-config > zellij/config.kdl`
gives you the *entire* default config (including all keybinds) to edit. Be aware
this replaces your minimal file with the full one.

**Custom layouts** — you can define a startup layout (e.g. editor on top, two
terminals below) as a `.kdl` file in `~/.config/zellij/layouts/` and launch it
with `zellij --layout mylayout`.

---

## Cheatsheet

| Want to…              | Keys                                      |
| --------------------- | ----------------------------------------- |
| New pane              | `Ctrl+p` `n`                              |
| Split right / down    | `Ctrl+p` `r` / `Ctrl+p` `d`              |
| Move focus            | `Ctrl+p` then arrows / `hjkl`            |
| Close pane            | `Ctrl+p` `x`                              |
| Fullscreen pane       | `Ctrl+p` `f`                              |
| New tab               | `Ctrl+t` `n`                              |
| Next/prev tab         | `Ctrl+t` then `→` / `←`                  |
| Resize                | `Ctrl+n` then arrows                      |
| Scroll / search       | `Ctrl+s`                                  |
| Detach                | `Ctrl+o` `d`                              |
| Lock (pass keys thru) | `Ctrl+g`                                  |
| Quit session          | `Ctrl+q`                                  |

> When in doubt, glance at the bottom status bar — it lists the live keys for
> whatever mode you're in.
