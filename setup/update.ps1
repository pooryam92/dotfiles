# Keep the installed apps current on Windows — the companion to install.ps1. (Config
# FILES are symlinks/junctions into this repo, so `git pull` already updates those;
# this only touches the apps install.ps1 installs via scoop.)
#
# install.ps1 is install-once (`scoop install` no-ops on apps already present), so
# re-running it never upgrades anything. scoop is the native updater here; this wrapper
# adds a "what's behind, to which version, and where are the release notes" view so you
# can spot breaking changes. The managed apps + changelogs live in tools.tsv (+ a base
# list in lib.ps1); shared helpers in lib.ps1. Linux uses update.sh.
#
#   .\setup\update.ps1            preview what's behind, confirm, then upgrade everything
#   .\setup\update.ps1 -Check     list ONLY what's behind (scoop status); no changes
#   .\setup\update.ps1 -Versions  full installed list (scoop list); no changes
param(
  [switch] $Check,
  [switch] $Versions
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  Warn "scoop not found — run install.ps1 first."
  exit 1
}

# ---------------------------------------------------------------------------
if ($Versions) {
  Info "Refreshing scoop manifests…"
  scoop update | Out-Null
  Info "Installed scoop apps:"
  scoop list
  $psfzf = Get-Module -ListAvailable PSFzf | Select-Object -First 1
  if ($psfzf) { Info "PSFzf module: $($psfzf.Version)" }
  $null = Show-Claude
  Info "Zed and Claude Code self-update, so they won't show as outdated in scoop."
  return
}

if ($Check) {
  # `scoop status` is scoop's native "what's behind, installed → latest" view.
  Info "Refreshing scoop manifests…"
  scoop update | Out-Null
  Info "Apps with a newer version available (empty = all current):"
  # Capture the outdated apps (success stream) so we can both show and count them.
  $outdated = @(scoop status 6>$null)
  if ($outdated) { $outdated | Format-Table -AutoSize | Out-Host } else { Info "All scoop apps are current." }
  $claudeBehind = Show-Claude
  Write-Host ""
  Show-Changelogs
  Info "Upgrade everything with:  .\setup\update.ps1"
  # Parity with `update.sh check`: exit 1 when anything is behind, 0 otherwise.
  if ($outdated.Count -gt 0 -or $claudeBehind) { exit 1 } else { exit 0 }
}

# --- update -----------------------------------------------------------------
# 1. Preview what's behind (scoop status shows installed → latest) + notes.
Info "Checking what's available before changing anything…"
scoop update | Out-Null
Info "Apps with a newer version available (empty = all current):"
scoop status
$null = Show-Claude
Write-Host ""
Show-Changelogs

# 2. Let you bail after seeing the preview (only when interactive).
if ([Environment]::UserInteractive -and -not $env:CI) {
  $ans = Read-Host "`nProceed with the upgrade? [Y/n]"
  if ($ans -match '^[Nn]') { Info "Aborted — nothing changed."; return }
}

# 3. Upgrade. scoop prints each app's old -> new transition. Scope to the apps
# install.ps1 manages (not `scoop update *`) so we don't drag along unrelated apps —
# mirrors update.sh's targeted apt upgrade. The list comes from tools.tsv + lib.ps1.
Info "Upgrading managed scoop apps to the latest…"
scoop update @(Get-ScoopApps)

# Bust the cached shell-init scripts. starship/zoxide cache their `init` output to disk
# and the profile's warm path (Initialize-Cached in pwsh/profile.ps1) treats that cache
# as DURABLE — it never re-checks the binary, so an upgraded starship/zoxide would keep
# running the OLD init shim across restarts until a manual refresh. Deleting the caches
# here makes the next shell regenerate them from the just-upgraded binaries.
$tmp = [IO.Path]::GetTempPath()
Remove-Item (Join-Path $tmp 'starship_init.ps1'), (Join-Path $tmp 'zoxide_init.ps1') -Force -ErrorAction SilentlyContinue

# PSFzf is a PSGallery module, not a scoop app — update it separately.
if (Get-Module -ListAvailable PSFzf) {
  Info "Updating PSFzf module…"
  try { Update-Module PSFzf -Force } catch { Warn "PSFzf update failed ($_)" }
}

# Claude Code — native installer, self-updating. `claude update` forces it now.
if (Get-Command claude -ErrorAction SilentlyContinue) {
  Info "Updating Claude Code…"
  try { claude update } catch { Warn "claude update failed; it also self-updates on launch" }
}

# Neovim's plugins update separately, from inside nvim: :lua vim.pack.update()
Info "Done. Restart your shell (. `$PROFILE) to pick up the new versions."
