# Installs dual-key-remap (CapsLock = Esc/Ctrl, Esc = CapsLock), the Windows counterpart
# of extras/keyd. Windows-only and opt-in: the root install.ps1 never touches it.
# See extras/dual-key-remap/README.md. Run elevated, e.g. via Windows' sudo:
#
#   sudo pwsh -File .\extras\dual-key-remap\install-dual-key-remap.ps1             install, link, start (idempotent)
#   sudo pwsh -File .\extras\dual-key-remap\install-dual-key-remap.ps1 update      fetch the latest release, restart
#   sudo pwsh -File .\extras\dual-key-remap\install-dual-key-remap.ps1 uninstall   stop, remove task and files
param(
  [string] $Command = 'install'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\..\setup\lib.ps1')

# Not in any scoop bucket, so the release zip is unpacked here. The exe reads config.txt
# from its own folder, so the repo's config is linked in next to it.
$DIR  = Join-Path $env:LOCALAPPDATA 'dual-key-remap'
$EXE  = Join-Path $DIR 'dual-key-remap.exe'
$TASK = 'DualKeyRemap'   # same name as upstream's add-to-startup.bat, so either replaces the other

function Assert-Admin {
  # The task runs elevated so remaps also reach admin windows (Task Manager, sudo shells);
  # registering such a task needs admin.
  $me = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
  if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run elevated: sudo pwsh -File $PSCommandPath $Command"
  }
}

function Stop-Remap {
  Get-Process dual-key-remap -ErrorAction SilentlyContinue | Stop-Process -Force
}

function Get-Release {
  $rel = Invoke-RestMethod 'https://api.github.com/repos/ililim/dual-key-remap/releases/latest'
  $zip = Join-Path $env:TEMP "dual-key-remap-$($rel.tag_name).zip"
  $tmp = Join-Path $env:TEMP "dual-key-remap-$($rel.tag_name)"
  Info "Downloading dual-key-remap $($rel.tag_name)…"
  Invoke-WebRequest ($rel.assets | Where-Object name -like '*.zip')[0].browser_download_url -OutFile $zip
  Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  Expand-Archive $zip $tmp
  # Older zips nest everything in a versioned folder, newer ones are flat.
  $new = Get-ChildItem $tmp -Recurse -Filter dual-key-remap.exe | Select-Object -First 1
  New-Item -ItemType Directory -Force -Path $DIR | Out-Null
  Stop-Remap
  Copy-Item -LiteralPath $new.FullName -Destination $EXE -Force
  Remove-Item -LiteralPath $zip, $tmp -Recurse -Force
}

function Start-Remap {
  Stop-Remap
  Start-ScheduledTask -TaskName $TASK
  # Poll instead of a fixed sleep: usually up in ~100ms, but give a slow start 5s.
  for ($i = 0; $i -lt 50 -and -not (Get-Process dual-key-remap -ErrorAction SilentlyContinue); $i++) {
    Start-Sleep -Milliseconds 100
  }
  if (-not (Get-Process dual-key-remap -ErrorAction SilentlyContinue)) {
    throw "dual-key-remap did not start — run '$EXE' directly to see the config error."
  }
}

function Invoke-Install {
  if (-not (Test-Path -LiteralPath $EXE)) { Get-Release }
  Link-Config (Join-Path $PSScriptRoot 'config.txt') (Join-Path $DIR 'config.txt')

  Info "Registering the '$TASK' logon task (elevated)…"
  # Full DOMAIN\user name: a bare USERNAME doesn't resolve for Azure AD accounts.
  $user      = [Security.Principal.WindowsIdentity]::GetCurrent().Name
  $action    = New-ScheduledTaskAction -Execute $EXE
  $trigger   = New-ScheduledTaskTrigger -AtLogOn -User $user
  $principal = New-ScheduledTaskPrincipal -UserId $user -RunLevel Highest -LogonType Interactive
  $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
  Register-ScheduledTask -TaskName $TASK -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

  Info "Starting dual-key-remap…"
  Start-Remap
  Info "Done. CapsLock: tap = Esc, hold = Ctrl. Esc = CapsLock. Cheat sheet: extras/dual-key-remap/README.md"
}

function Invoke-Update {
  if (-not (Test-Path -LiteralPath $EXE)) { Warn "dual-key-remap not found — run install first."; exit 1 }
  Get-Release
  Start-Remap
  Info "Done."
}

function Invoke-Uninstall {
  Info "Stopping dual-key-remap…"
  Stop-Remap
  Unregister-ScheduledTask -TaskName $TASK -Confirm:$false -ErrorAction SilentlyContinue
  # Removing the folder only drops the config link, never the repo file.
  Remove-Item -LiteralPath $DIR -Recurse -Force -ErrorAction SilentlyContinue
  Info "Done."
}

Assert-Admin
switch ($Command.ToLower()) {
  'install'   { Invoke-Install }
  'update'    { Invoke-Update }
  'uninstall' { Invoke-Uninstall }
  default     { Write-Host "usage: sudo pwsh -File .\extras\dual-key-remap\install-dual-key-remap.ps1 [install|update|uninstall]"; exit 2 }
}
