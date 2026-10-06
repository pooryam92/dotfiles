# komorebi — niri-style scrolling on Windows

[komorebi](https://github.com/LGUG2Z/komorebi) is a tiling window manager for
Windows; [whkd](https://github.com/LGUG2Z/whkd) is the small hotkey daemon that
drives it. Together they give Windows the [niri](../niri/README.md) workflow:
windows sit in a **strip of columns wider than the screen**, a new window adds a
column instead of shrinking the others, and the **same Super-key shortcuts** as
`extras/niri/config.kdl` (Win = Super) scroll the view along it.

- Configs: [`komorebi.json`](komorebi.json) (layouts, gaps, monitors) and
  [`whkdrc`](whkdrc) (hotkeys)
- Installed by [`install-komorebi.ps1`](install-komorebi.ps1), which links them to
  `~\komorebi.json` and `~\.config\whkdrc`. Edits are live after a reload (see below).
- Windows-only and opt-in: the root `install.ps1` never touches it.

> **License.** komorebi and whkd are free for **personal** use only. Using them for
> work needs a paid
> [Individual Commercial Use License](https://lgug2z.com/software/komorebi).

## Install / remove

```powershell
.\extras\komorebi\install-komorebi.ps1             # scoop install, link, fetch app rules, autostart, start
.\extras\komorebi\install-komorebi.ps1 update      # upgrade both, refresh app rules, restart
.\extras\komorebi\install-komorebi.ps1 uninstall   # stop, remove autostart, unlink, scoop uninstall, wipe state
```

komorebi + whkd start at every login from `shell:startup\komorebi.lnk`, which the
installer creates with `komorebic enable-autostart --whkd`. It's a login shortcut,
not a Windows service, because services run with no desktop and couldn't see
windows or keys.

The installer also downloads `~\applications.json`. These are community rules for
apps that misbehave when tiled (tray popups, splash screens). It's downloaded,
not kept in the repo; `update` re-downloads it. The root `install.ps1 update`
doesn't touch komorebi, so run this one too. It warns when the `$schema` version
pinned in `komorebi.json` falls behind the installed komorebi.

## Scrolling, per screen

Every workspace uses komorebi's `Scrolling` layout. Each physical screen is
pinned to its own config by ID in `display_index_preferences`, so the laptop and
the ultrawide each keep their own column count.

| Config index | Screen | Columns |
| --- | --- | --- |
| 0 (`L1`–`L9`) | Laptop panel `LEN4146` (1920 logical) | **2** side by side |
| 1 (`W1`–`W9`) | Samsung S34C65xU ultrawide (3440×1440) | **1** "spotlight" column in the center 2752px (80%, niri's default width) |

```
ultrawide, 5 windows, focus on 3
       ┌──────┬────────────┬──────┐
  1 ◀  │  2 ▸ │    [3]     │ ◂ 4  │  ▶ 5
       │ peek │   2752px   │ peek │
       └──────┴────────────┴──────┘
  Win+←/→ slides the strip; the focused window is always the big center one
```

On the ultrawide, `work_area_offset` shrinks the tiling area to the center 2752px (80%, matching
`default-column-width` in `extras/niri/config.kdl`),
so the one visible column always sits in the middle of the curve. (komorebi's
offset `right` shrinks the *width*, so centering with 344px on each side takes
`left: 344, right: 688`.) The neighbouring
columns lie just outside that area, so their inner ~340px shows in the side strips,
like niri's peeking columns. At either end of the strip that side is empty.

The laptop's 2 columns come from `layout_defaults`, so its workspaces only name the
layout; the ultrawide's workspaces override it with `columns: 1`.

Gaps match niri's `gaps 8`: komorebi pads each tile on every side, so 4px of
container padding makes an 8px gap between tiles, and 4px of workspace padding on
top makes 8px at the screen edge.

`Win+R` / `Win+Shift+R` switch the focused workspace to 1 / 2 columns until the
next reload.

A new screen (another office monitor) has no entry yet. To add one, run
`komorebic monitor-information`, copy its `serial_number_id` into
`display_index_preferences`, and add a matching `monitors` entry. The laptop panel
reports no serial number, so its entry uses the `device_id` instead.

## Hotkeys (same as niri)

Copied from [`extras/niri/config.kdl`](../niri/config.kdl). Every direction works
with both **h/j/k/l and the arrow keys**.

| Keys | Action |
| --- | --- |
| `Win` + `h`, `←→` | focus column left / right (scrolls the strip) |
| `Win` + `j/k`, `↓↑` | next / previous window in a stack |
| `Win+Ctrl` + direction | move the window left / right, or reorder it in its stack |
| `Win+Shift` + direction | previous / next monitor (`+Ctrl`: take the window along) |
| `Win+u/i`, `Win+PgDn/PgUp` | next / previous workspace (`+Ctrl`: take the window along) |
| `Win+1…9` / `Win+Ctrl+1…9` | go to / send window to workspace |
| `Win+[` / `Win+]` / `Win+.` | stack the window into the left / right column; unstack it |
| `Win+r` / `Win+Shift+r` | 1 / 2 visible columns |
| `Win+f` / `Win+m` | maximize column (monocle) / maximize window |
| `Win+g` / `Win+Shift+g` | float / unfloat the window; jump between floating and tiled windows |
| `Win+o` | overview (Windows Task View) |
| `Win+Shift+/` (`Win+?`) | cheat sheet of every bind (`komorebi-shortcuts`) |
| `Win+q` / `Win+t` | close window / WezTerm |
| `Win+Ctrl+r` | reload `komorebi.json` (in niri this resets window height) |

**Different from niri, because komorebi or Windows forces it:**

- **`Win+L` always locks Windows.** The OS reserves it and no app can rebind it, so
  "focus right" is `Win+→`. The `Shift`/`Ctrl` + `l` combos are bound; if one
  locks your machine, use the arrow instead.
- **Float is `G` on both**, not niri's default `Mod+V`: `Win+v` stays Windows'
  clipboard history, so `extras/niri/config.kdl` was moved to `Mod+G` to match.
- **All columns share one width.** niri sizes each column (`Mod+R` cycles 50/67/80%);
  komorebi only sets how many fit on screen. Per-column width, `Mod+C` (center),
  `Mod+Home/End` and `Mod+±` have no equivalent.
- **A column holds one window at a time.** A komorebi stack works like niri's
  *tabbed* column (`Mod+W`), not a vertical split. A stacked column gets an amber
  border and a row of title tabs on top, so hidden windows don't get lost.
- **Animation is shorter and plainer.** Moves slide (150ms, ease-out) instead of
  niri's spring. If windows flicker, set `animation.enabled` to `false`.
- **No equivalent:** `Mod+Home/End`, `Mod+Comma` (pull a window in), `Mod+Shift+U/I`
  (reorder workspaces), `Mod+Escape`, `Mod+Shift+E`, `Mod+Shift+P`.
- `Win` alone stays Windows' Start menu, standing in for niri's launcher (`Mod+D`).

## Editing

- `komorebi.json`: press `Win+Ctrl+r` (`komorebic replace-configuration`). It rebuilds
  the workspaces, so windows can all land on the first one; send them back with
  `Win+Ctrl+N`. (`komorebic reload-configuration` does *not* re-read the JSON.)
- `whkdrc`: run `komorebic stop --whkd; komorebic start --whkd`.

## Troubleshooting

- **komorebi won't start**: run `komorebi.exe` directly; it prints the config
  error with a line number. `komorebic check` confirms which files it found.
- **A window won't tile, or tiles when it shouldn't**: `Win+g` floats it. For a
  permanent fix, add an `ignore_rules` / `manage_rules` entry to `komorebi.json`.
- **An app never tiles at all** (absent from `komorebic state`): it may announce its
  window with a title change instead of a "show" event, like SSMS and other Visual
  Studio-based apps do. Add its exe to `object_name_change_applications`.
- **Hotkeys fire twice**: two whkd instances are running. `Get-Process whkd`
  always lists two, because scoop's shim launches the real exe; four or more means
  duplicates. Run `komorebic stop --whkd`, then `Get-Process whkd | Stop-Process`,
  then start again.
- **Windows land on the wrong screen after docking**: Windows Settings → System →
  Display → Multiple displays: turn **off** "Remember window locations based on
  monitor connection".
