# Dotfiles front door for Windows — installs and updates the terminal/CLI stack.
# install is install-once (scoop install no-ops on apps already present); update upgrades.
#
#   .\install.ps1              install everything (default)
#   .\install.ps1 update       force every managed app to its latest release
#
# First run, before pwsh 7 exists, under Windows PowerShell 5.1:
#   powershell -ExecutionPolicy Bypass -File install.ps1
#
# Enable Windows "Developer Mode" once (Settings -> System -> For developers) so file
# symlinks can be created unprivileged; otherwise configs are copied instead.
param(
  [string] $Command = 'install'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'setup\lib.ps1')

# --- install ----------------------------------------------------------------
function Invoke-Install {
  Info "Setting ExecutionPolicy (CurrentUser -> RemoteSigned)…"
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

  # --- packages ------------------------------------------------------------
  Ensure-Scoop
  # The nvim config is colorscheme-only, so zig and the tree-sitter CLI stay out.
  Info "Installing packages via scoop…"
  scoop install @($SCOOP_APPS)

  # Not a scoop app, and the official installer self-updates, so run it only when absent.
  Info "Installing Claude Code…"
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    Info "claude already installed ($(claude --version 2>$null))"
  } else {
    try { Invoke-RestMethod -Uri 'https://claude.ai/install.ps1' | Invoke-Expression }
    catch { Warn "Claude Code install failed ($_). See https://docs.anthropic.com/en/docs/claude-code" }
  }

  Test-NvimShadow
  Test-WeztermShadow

  # --- config links --------------------------------------------------------
  $profilePath = Resolve-ProfilePath
  Invoke-Links $profilePath

  # -------------------------------------------------------------------------
  Info "Done. Open WezTerm to start using the new setup."
  Info "It launches pwsh with the native prompt; Alt+\\ splits, Ctrl+p = pane mode."
  Warn "If configs were COPIED (not linked), enable Developer Mode and re-run for live edits."
}

# --- update -----------------------------------------------------------------

function Invoke-Update {
  if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) { Warn "scoop not found — run install first."; exit 1 }

  Info "Refreshing scoop manifests…"
  scoop update | Out-Null
  # scoop treats every nightly stamp as equal, so without update_nightly it never moves
  # wezterm-nightly forward. Idempotent; set here so existing machines pick it up too.
  scoop config update_nightly true | Out-Null
  # scoop refuses to replace an app with a running process, and this shell normally lives
  # inside WezTerm, so skip wezterm-nightly with a pointer when that WezTerm is scoop's.
  $apps = $SCOOP_APPS
  if ($env:WEZTERM_EXECUTABLE -like (Join-Path $env:USERPROFILE 'scoop\apps\wezterm-nightly\*')) {
    Warn "Running inside scoop's WezTerm, so wezterm-nightly is skipped (scoop won't replace a running app)."
    Warn "    To move WezTerm forward, run '.\install.ps1 update' from Windows Terminal or conhost."
    $apps = $apps | Where-Object { $_ -ne 'wezterm-nightly' }
  }
  Info "Upgrading managed scoop apps to the latest…"
  scoop update @($apps)
  Test-WeztermShadow

  # The profile caches zoxide's init to disk and never re-checks the binary, so delete the
  # cache or an upgraded zoxide keeps running the old init.
  $tmp = [IO.Path]::GetTempPath()
  Remove-Item (Join-Path $tmp 'zoxide_init.ps1') -Force -ErrorAction SilentlyContinue

  if (Get-Command claude -ErrorAction SilentlyContinue) {
    Info "Updating Claude Code…"
    try { claude update } catch { Warn "claude update failed; it also self-updates on launch" }
  }

  Info "Done. Restart your shell (. `$PROFILE) to pick up the new versions."
}

function Show-Usage {
  Write-Host @'
usage: .\install.ps1 [command]
  install     install the terminal/CLI stack (default; idempotent, safe to re-run)
  update      force every managed app to its latest release
'@
}

# ---------------------------------------------------------------------------
switch ($Command.ToLower()) {
  'install'  { Invoke-Install }
  'update'   { Invoke-Update }
  { $_ -in 'help','-h','--help' } { Show-Usage }
  default    { Write-Host "unknown command: $Command`n"; Show-Usage; exit 2 }
}
