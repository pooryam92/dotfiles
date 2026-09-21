# Installs Zed (opt-in; not part of install.ps1, which links the config). Self-updates.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\setup\lib.ps1')

# Ensure-Scoop also adds the 'extras' bucket, where the zed manifest lives.
Ensure-Scoop
if (Get-Command zed -ErrorAction SilentlyContinue) {
  Info "zed already installed ($(zed --version 2>$null)); it self-updates."
} else {
  Info "Installing Zed via scoop…"
  scoop install zed
}
Info "Config is linked by install.ps1 (zed/settings.json, zed/keymap.json). See zed/README.md."
