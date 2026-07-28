# Install VS Code — the GUI editor — Windows, OPT-IN.
#
# This is NOT part of install.ps1. install.ps1 manages the terminal/CLI stack
# (PowerShell 7, WezTerm, zoxide, Neovim, Claude Code, the Nerd Font…);
# VS Code is a GUI app, so it installs on its own — mirroring the Linux
# vscode/install-vscode.sh, the same way Zed does. VS Code's *config* files are
# still linked by install.ps1's Invoke-Links (vscode/settings.json,
# vscode/keybindings.json via links.tsv); only the install lives here.
#
# VS Code self-updates afterwards, so `install.ps1 update` never touches it.
# Re-running this is safe: both steps below are guarded / idempotent.
#
# WHY winget AND NOT SCOOP, when the rest of the repo is scoop:
#   scoop's `vscode` manifest runs VS Code in PORTABLE mode — it persists a
#   `data\` directory inside the scoop app folder and reads settings from
#   <scoop>\persist\vscode\data\user-data\User\ instead of %APPDATA%\Code. That
#   path isn't stable enough to name in links.tsv, and it would fork the config
#   path from Linux for no benefit (goal #3). winget's user-scope install is
#   also admin-free and puts settings at %APPDATA%\Code\User, matching Linux's
#   ~/.config/Code/User. scoop stays the tool for the CLI stack.
#
# Linux counterpart: vscode/install-vscode.sh. See vscode/README.md.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\setup\lib.ps1')

# --- VS Code itself ---------------------------------------------------------
if (Get-Command code -ErrorAction SilentlyContinue) {
  Info "VS Code already installed ($(code --version 2>$null | Select-Object -First 1)); it self-updates."
} elseif (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Warn "winget not found. Install 'App Installer' from the Microsoft Store, or get VS Code from https://code.visualstudio.com/download"
} else {
  # --scope user  = no admin, installs under %LOCALAPPDATA%\Programs
  # The two --accept flags keep it non-interactive.
  Info "Installing VS Code via winget (user scope, no admin)…"
  winget install --id Microsoft.VisualStudioCode --scope user `
    --accept-package-agreements --accept-source-agreements
  # winget adds VS Code's bin dir to the *persisted* user PATH, but this session's
  # PATH is a stale copy — add it so the extension step below can find `code`.
  $env:Path = (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin') + ';' + $env:Path
}

# --- Extensions -------------------------------------------------------------
# The things settings.json can't provide on its own. WHICH extensions is data —
# vscode/extensions.txt, read by this script AND by install-vscode.sh, so the two
# OSes can't drift (goal #3). Strip `# comments` and blanks; ids never contain #.
# `--force` makes this idempotent (it no-ops when the extension is already
# present and current) instead of erroring on a re-run.
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
  # Backtick is PowerShell's escape char, so 'code' is quoted, not ``code``.
  Warn "'code' not on PATH yet — open a NEW shell and re-run this script to install: $($extensions -join ', ')"
}

Info "Config is linked by install.ps1 (vscode/settings.json, vscode/keybindings.json). See vscode/README.md."
Info "Note: .md files open RENDERED by default — press Ctrl+Shift+V to edit the source."
