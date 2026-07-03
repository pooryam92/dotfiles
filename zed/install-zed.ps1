# Install Zed — the GUI editor — Windows, OPT-IN.
#
# This is NOT part of install.ps1. install.ps1 manages the terminal/CLI stack
# (PowerShell 7, WezTerm, zoxide, Neovim, Claude Code, the Nerd Font…);
# Zed is a GUI app, so it installs on its own — mirroring the Linux
# zed/install-zed.sh. Zed's *config* files are still linked by install.ps1's
# Invoke-Links (zed/settings.json, zed/keymap.json via links.tsv); only the
# install lives here.
#
# Zed self-updates afterwards, so `install.ps1 update` never touches it. Re-running is safe:
# `scoop install` no-ops when zed is already present.
#
# Linux counterpart: zed/install-zed.sh. See docs/zed.md.
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
Info "Config is linked by install.ps1 (zed/settings.json, zed/keymap.json). See docs/zed.md."
