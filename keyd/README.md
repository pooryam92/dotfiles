# keyd — keyboard remapping

[keyd](https://github.com/rvaiya/keyd) is a small daemon that remaps keys at the
**evdev layer** — below the display server. That means the remaps apply
everywhere the same way: niri, stock COSMIC (`cosmic-comp`), X11, and even a bare
TTY. It's the one tool that gives us *identical* keyboard behaviour across every
session, which fits the repo's "one experience" goal.

- Config (source of truth): [`keyd/default.conf`](../keyd/default.conf)
- Installed by [`install.sh`](../install.sh) → copied to `/etc/keyd/default.conf`
- Linux-only. The Windows counterpart would be PowerToys Keyboard Manager.

## What it remaps

| Physical key | Tap | Hold |
|---|---|---|
| **CapsLock** | Esc | Ctrl |
| **Esc** | CapsLock | — |
| **Left Ctrl** | Super (niri's `Mod`) | Super |

`overload(layer, key)` is keyd's tap-hold: holding activates the modifier
instantly (no lag, so chords work), while a quick tap-and-release emits the other
key. CapsLock uses it; Left Ctrl is a plain remap.

### Why Left Ctrl → Super

The laptop's physical **Super key is dead** — a failed switch. We confirmed it
sends *no* event to Linux at all (checked with `keyd monitor` and
`libinput debug-events`, with keyd stopped, watching every device), while it
worked under Windows. It's not a software/driver issue and there's no firmware or
BIOS "Windows-key lock" on this machine — so it's hardware, and not fixable in
config.

Remapping **Left Ctrl → Super** restores a working `Mod` key on the left, where
muscle memory expects it. Nothing is lost: **Ctrl** is still available by
**holding CapsLock**, and **Right Ctrl** is untouched.

## Build / install

keyd isn't in Pop!_OS 24.04's apt repos, so `install.sh` builds it from source
(`git clone … && make && sudo make install`) and enables the service. The build
is tiny. Re-running `install.sh` is idempotent: it skips the build if `keyd` is
already on `PATH` and always re-syncs the config.

## Apply config changes

`/etc/keyd/default.conf` is a **copy**, not a symlink (keyd starts at boot,
possibly before `$HOME` is mounted, so a symlink into the repo would be fragile).
After editing `keyd/default.conf`, push it live with:

```bash
sudo install -Dm644 keyd/default.conf /etc/keyd/default.conf && sudo keyd reload
```

(or just re-run `./install.sh`).

## Debugging

- `sudo keyd monitor` — live view of key events as keyd sees and rewrites them.
- `keyd --version` — installed version.
- `systemctl status keyd` — service state; `journalctl -u keyd` for errors.
