# Keep the installed TOOLS current on Windows — the companion to install.ps1.
# (The config FILES are symlinks/junctions into this repo, so `git pull` already
# updates those; this script only touches the apps install.ps1 installs via scoop.)
#
# install.ps1 is install-once (`scoop install` no-ops on apps already present), so
# re-running it never upgrades anything. scoop is the native updater here; this
# wrapper adds a "what's behind, to which version, and where are the release notes"
# view so you can spot breaking changes. Linux uses update.sh.
#
#   .\update.ps1            preview what's behind, confirm, then upgrade everything
#   .\update.ps1 -Check     list ONLY what's behind (scoop status); no changes
#   .\update.ps1 -Versions  full installed list (scoop list); no changes
param(
  [switch] $Check,
  [switch] $Versions
)
$ErrorActionPreference = 'Stop'

function Info($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Host "!!  $msg" -ForegroundColor Yellow }

# Release-notes / changelog per app — printed so you can check breaking changes.
$Changelog = [ordered]@{
  pwsh              = 'https://github.com/PowerShell/PowerShell/releases'
  neovim            = 'https://github.com/neovim/neovim/releases'
  starship          = 'https://github.com/starship/starship/releases'
  wezterm           = 'https://wezfurlong.org/wezterm/changelog.html'
  fzf               = 'https://github.com/junegunn/fzf/releases'
  win32yank         = 'https://github.com/equalsraf/win32yank/releases'
  zoxide            = 'https://github.com/ajeetdsouza/zoxide/releases'
  zed               = 'https://zed.dev/releases'
  'JetBrainsMono-NF'= 'https://github.com/ryanoasis/nerd-fonts/releases'
  claude            = 'https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md'
}

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  Warn "scoop not found — run install.ps1 first."
  exit 1
}

# Claude Code isn't a scoop app — report it separately (installed vs npm latest).
# Returns $true when behind (so -Check can fold it into its exit code). Callers
# that only want the printout use `$null = Show-Claude` to swallow the boolean.
function Show-Claude {
  if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { return $false }
  $latest = try { (Invoke-RestMethod 'https://registry.npmjs.org/@anthropic-ai/claude-code/latest').version } catch { '?' }
  $cur = (claude --version 2>$null)
  # Escape the version so its dots match literally, not as regex wildcards.
  if ($latest -ne '?' -and $cur -match [regex]::Escape($latest)) {
    Info "Claude Code: $cur (up to date)"; return $false
  }
  Info "Claude Code: $cur  →  $latest    $($Changelog.claude)"; return $true
}

# Release-notes links — handy for checking breaking changes before/after.
function Show-Changelogs {
  Info "Release notes (check for breaking changes):"
  foreach ($k in $Changelog.Keys) { Write-Host ("   {0,-18} {1}" -f $k, $Changelog[$k]) }
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
  # Capture the outdated apps (success stream) so we can both show them and count
  # them; the manifests are already refreshed above, so this is cheap.
  $outdated = @(scoop status 6>$null)
  if ($outdated) { $outdated | Format-Table -AutoSize | Out-Host } else { Info "All scoop apps are current." }
  $claudeBehind = Show-Claude
  Write-Host ""
  Show-Changelogs
  Info "Upgrade everything with:  .\update.ps1"
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

# 3. Upgrade. scoop prints each app's old -> new transition as it goes. Scope to
# the apps install.ps1 manages (not `scoop update *`) so we don't drag along
# unrelated scoop apps — mirrors update.sh's targeted apt upgrade. Keep this list
# in sync with $pkgs in install.ps1.
Info "Upgrading managed scoop apps to the latest…"
$apps = @('pwsh', 'neovim', 'starship', 'wezterm', 'fzf', 'win32yank',
          'zoxide', 'zed', 'python', 'JetBrainsMono-NF')
scoop update @apps

# Bust the cached shell-init scripts. starship/zoxide cache their `init` output to
# disk and the profile's warm path (Initialize-Cached in pwsh/profile.ps1) treats
# that cache as DURABLE — it never re-checks the binary, so an upgraded starship/
# zoxide would keep running the OLD init shim across restarts/reboots until a manual
# refresh. Deleting the caches here makes the next shell regenerate them from the
# just-upgraded binaries, so the "restart your shell" message below is actually true.
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

# cheat + keymap (Textual) — keep the shared tools venv current.
$cheatPy = Join-Path $env:USERPROFILE '.local\share\cheat\venv\Scripts\python.exe'
if (Test-Path $cheatPy) {
  Info "Upgrading Textual (cheat + keymap)…"
  & $cheatPy -m pip install -q --upgrade textual
  if ($LASTEXITCODE -ne 0) { Warn "Textual upgrade failed" }
}

# Neovim's plugins update separately, from inside nvim: :lua vim.pack.update()
Info "Done. Restart your shell (. `$PROFILE) to pick up the new versions."
