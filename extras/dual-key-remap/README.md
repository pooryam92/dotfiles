# dual-key-remap — CapsLock as Esc/Ctrl on Windows

[dual-key-remap](https://github.com/ililim/dual-key-remap) is a tiny Windows key
remapper with tap/hold support. It's the Windows counterpart of
[keyd](../keyd/README.md), so the keyboard feels the same on both OSes.

- Config: [`config.txt`](config.txt), linked to `%LOCALAPPDATA%\dual-key-remap\config.txt`
  (the exe only reads `config.txt` from its own folder)
- Installed by [`install-dual-key-remap.ps1`](install-dual-key-remap.ps1). The tool
  isn't in any scoop bucket, so the script downloads the latest GitHub release zip.
- Windows-only and opt-in: the root `install.ps1` never touches it.

## What it remaps

| Physical key | Tap | Hold |
| --- | --- | --- |
| **CapsLock** | Esc | Ctrl |
| **Esc** | CapsLock | CapsLock |

Same as keyd's first two lines. keyd's third remap, **Right Alt → Super**, is left
out: it only works around a dead Super key under Linux, and on Windows it would
cost AltGr.

## Install / remove

All three need an elevated shell, so prefix them with Windows' `sudo`:

```powershell
sudo pwsh -File .\extras\dual-key-remap\install-dual-key-remap.ps1             # download, link, register task, start
sudo pwsh -File .\extras\dual-key-remap\install-dual-key-remap.ps1 update      # fetch the latest release, restart
sudo pwsh -File .\extras\dual-key-remap\install-dual-key-remap.ps1 uninstall   # stop, remove task and files
```

**Why elevated.** A program that isn't elevated can't remap keys while an elevated
window has focus (Task Manager, a `sudo` shell). So the installer starts it from an
elevated **logon scheduled task** (`DualKeyRemap`, the same one upstream's
`add-to-startup.bat` creates), not from the Startup folder.

## Editing

Edit `config.txt`, then pick **Reload** from the tray icon. Key names are listed in
the [wiki](https://github.com/ililim/dual-key-remap/wiki/Using-config.txt#key-names).
To get a remap's output, press the other keys **first** and the remapped key last.
For example, Shift then CapsLock sends Shift+Esc.

## Troubleshooting

- **Nothing remaps**: check the tray icon is there. The task may not have
  run: `Start-ScheduledTask DualKeyRemap`. A config error shows a message box
  when the exe starts.
- **Doesn't work on the login screen**: expected. It starts once you're logged in.
