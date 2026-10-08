# Installs komorebi (tiling window manager) + whkd (its hotkey daemon), links this folder's
# configs and starts both. Windows-only and opt-in: the root install.ps1 never touches it.
# See extras/komorebi/README.md.
#
#   .\extras\komorebi\install-komorebi.ps1              install, link, start (idempotent)
#   .\extras\komorebi\install-komorebi.ps1 update       upgrade both, refresh app rules, restart
#   .\extras\komorebi\install-komorebi.ps1 uninstall    stop, remove autostart, unlink, remove everything
param(
  [string] $Command = 'install'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\..\setup\lib.ps1')

# komorebi reads ~/komorebi.json and whkd reads ~/.config/whkdrc unless overridden by env vars.
$LINKS = @(
  @{ Src = Join-Path $PSScriptRoot 'komorebi.json'; Dst = Join-Path $env:USERPROFILE 'komorebi.json' }
  @{ Src = Join-Path $PSScriptRoot 'whkdrc';        Dst = Join-Path $env:USERPROFILE '.config\whkdrc' }
)
# Community rules for apps that misbehave when tiled; downloaded, not kept in the repo.
$ASC = Join-Path $env:USERPROFILE 'applications.json'

# Start at login from the HKCU Run key, not komorebic enable-autostart's shell:startup
# shortcut: Explorer runs the Startup folder after every Run entry, which held komorebi
# back ~3.5 min after login. Not a Windows service either: services run in session 0
# with no desktop, so they couldn't see windows or hotkeys.
$RUN_KEY  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$RUN_NAME = 'komorebi'
$OLD_LNK  = Join-Path ([Environment]::GetFolderPath('Startup')) 'komorebi.lnk'

function Stop-Komorebi {
  # komorebic panics when there's no komorebi to talk to, so only stop a running one.
  if (Get-Process komorebi -ErrorAction SilentlyContinue) { komorebic stop --whkd }
  Get-Process whkd -ErrorAction SilentlyContinue | Stop-Process -Force
}

function Start-Komorebi {
  Info "Starting komorebi + whkd…"
  Stop-Komorebi
  # stop dumps the layout to %TEMP%\komorebi.state.json and start re-applies it, which
  # would override the workspaces in the (possibly just-updated) config.
  komorebic start --whkd --clean-state
  if (-not (Get-Process komorebi -ErrorAction SilentlyContinue)) {
    throw "komorebi did not start — run 'komorebi.exe' directly to see the config error."
  }
}

function Invoke-Install {
  Ensure-Scoop
  Info "Installing komorebi + whkd via scoop…"
  scoop install komorebi whkd

  foreach ($l in $LINKS) { Link-Config $l.Src $l.Dst }

  Info "Fetching applications.json…"
  komorebic fetch-app-specific-configuration

  # scoop's `current` junction keeps this path valid across updates. The no-console build
  # flashes no window; --clean-state makes the config win over any saved layout.
  Info "Enabling start at login (HKCU Run\$RUN_NAME)…"
  $exe = Join-Path $env:USERPROFILE 'scoop\apps\komorebi\current\komorebic-no-console.exe'
  Set-ItemProperty -Path $RUN_KEY -Name $RUN_NAME -Value "`"$exe`" start --whkd --clean-state"
  Remove-Item -LiteralPath $OLD_LNK -Force -ErrorAction SilentlyContinue

  Start-Komorebi

  Info "Done. niri keys: Win+h/arrows focus, add Ctrl to move, Win+u/i or Win+1-9 workspaces. Cheat sheet: extras/komorebi/README.md"
}

# The root install.ps1 update doesn't know about komorebi, so this is the only path that
# moves it forward. scoop won't replace a running app, so stop it first.
function Invoke-Update {
  if (-not (Get-Command komorebic -ErrorAction SilentlyContinue)) { Warn "komorebi not found — run install first."; exit 1 }
  Info "Updating komorebi + whkd via scoop…"
  scoop update | Out-Null
  # Stop only now, so tiling and hotkeys stay up while the buckets refresh.
  Stop-Komorebi
  scoop update komorebi whkd

  Info "Refreshing applications.json…"
  komorebic fetch-app-specific-configuration
  Start-Komorebi

  # komorebi.json pins its $schema to a release; a stale pin means editor hints for old options.
  $have = (komorebic --version | Select-Object -First 1) -replace '^komorebic\s+', ''
  $json = Join-Path $PSScriptRoot 'komorebi.json'
  if (-not (Select-String -LiteralPath $json -SimpleMatch "/v$have/schema.json" -Quiet)) {
    Warn "komorebi is now v$have — bump the `$schema version in extras/komorebi/komorebi.json to match."
  }
  Info "Done."
}

function Invoke-Uninstall {
  Info "Stopping komorebi + whkd…"
  Stop-Komorebi
  Remove-ItemProperty -Path $RUN_KEY -Name $RUN_NAME -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $OLD_LNK -Force -ErrorAction SilentlyContinue

  # Only remove our links; a real file at the path is the user's, so leave it.
  foreach ($l in $LINKS) {
    $item = Get-Item -LiteralPath $l.Dst -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType) { Remove-Item -LiteralPath $l.Dst -Force; Info "unlinked $($l.Dst)" }
    elseif ($item) { Warn "left $($l.Dst) in place (not a link — may be a copy; delete by hand)" }
  }
  Remove-Item -LiteralPath $ASC -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath (Join-Path $env:LOCALAPPDATA 'komorebi') -Recurse -Force -ErrorAction SilentlyContinue

  Info "Removing komorebi + whkd from scoop…"
  scoop uninstall komorebi whkd
  Info "Done."
}

switch ($Command.ToLower()) {
  'install'   { Invoke-Install }
  'update'    { Invoke-Update }
  'uninstall' { Invoke-Uninstall }
  default     { Write-Host "usage: .\extras\komorebi\install-komorebi.ps1 [install|update|uninstall]"; exit 2 }
}
