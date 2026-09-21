# Installs VS Code (opt-in; not part of install.ps1, which links the config). Self-updates.
# winget, not scoop: scoop's vscode manifest runs VS Code in portable mode, keeping
# settings under scoop\persist instead of %APPDATA%\Code.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\setup\lib.ps1')

# --- VS Code itself ---------------------------------------------------------
if (Get-Command code -ErrorAction SilentlyContinue) {
  Info "VS Code already installed ($(code --version 2>$null | Select-Object -First 1)); it self-updates."
} elseif (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Warn "winget not found. Install 'App Installer' from the Microsoft Store, or get VS Code from https://code.visualstudio.com/download"
} else {
  Info "Installing VS Code via winget (user scope, no admin)…"
  winget install --id Microsoft.VisualStudioCode --scope user `
    --accept-package-agreements --accept-source-agreements
  # winget updates the persisted PATH, not this session's — prepend the bin dir.
  $env:Path = (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin') + ';' + $env:Path
}

# --- Extensions -------------------------------------------------------------
# Which extensions to install is data: vscode/extensions.txt, shared with
# install-vscode.sh. --force makes --install-extension idempotent.
$extensions = Get-Content (Join-Path $PSScriptRoot 'extensions.txt') |
  ForEach-Object { ($_ -split '#')[0].Trim() } |
  Where-Object { $_ }
if (Get-Command code -ErrorAction SilentlyContinue) {
  foreach ($ext in $extensions) {
    Info "Installing extension $ext…"
    try { code --install-extension $ext --force }
    catch { Warn "could not install $ext ($_); install it from the Extensions view" }
  }
} else {
  Warn "'code' not on PATH yet — open a NEW shell and re-run this script to install: $($extensions -join ', ')"
}

Info "Config is linked by install.ps1 (vscode/settings.json, vscode/keybindings.json). See vscode/README.md."
Info "Note: .md files open RENDERED by default — press Ctrl+Shift+V to edit the source."
