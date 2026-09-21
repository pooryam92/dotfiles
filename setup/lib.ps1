# Shared helpers for install.ps1 — dot-sourced, never
# run directly: logging, the link helpers, the scoop app list, and the per-tool steps.

$LIB = $PSScriptRoot                       # …\setup — this lib + links.tsv live here
$DOT = Split-Path -Parent $LIB             # repo root — where the config sources live

$SCOOP_APPS = @('pwsh', 'fzf', 'win32yank', 'zed',
                'wezterm-nightly', 'zoxide', 'fd', 'ripgrep', 'bat',
                'neovim', 'JetBrainsMono-NF')

function Info($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Host "!!  $msg" -ForegroundColor Yellow }

# --- config links (links.tsv) ------------------------------------------------
function Read-Links { Import-Csv -Delimiter "`t" -Path (Join-Path $LIB 'links.tsv') }

# Junctions need no privilege, but file symlinks need Developer Mode or admin, so they
# fall back to a plain copy (with a warning) when not permitted.
function Link-Config {
  param(
    [Parameter(Mandatory)] [string] $Src,
    [Parameter(Mandatory)] [string] $Dst,
    [switch] $Directory
  )
  if (-not (Test-Path -LiteralPath $Src)) { Warn "source missing, skipping: $Src"; return }
  $parent = Split-Path -Parent $Dst
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }

  $existing = Get-Item -LiteralPath $Dst -Force -ErrorAction SilentlyContinue
  if ($existing) {
    if ($existing.LinkType) {
      # Remove the reparse point only, never the target.
      if ($Directory) { [System.IO.Directory]::Delete($Dst) }
      else { Remove-Item -LiteralPath $Dst -Force }
    } else {
      $backup = "$Dst.bak." + (Get-Date -Format 'yyyyMMddHHmmss')
      Move-Item -LiteralPath $Dst -Destination $backup
      Warn "backed up existing $Dst -> $backup"
    }
  }

  $type = if ($Directory) { 'Junction' } else { 'SymbolicLink' }
  try {
    New-Item -ItemType $type -Path $Dst -Target $Src -ErrorAction Stop | Out-Null
    Info "linked $Dst -> $Src"
  } catch {
    Copy-Item -LiteralPath $Src -Destination $Dst -Recurse:$Directory -Force
    Warn "symlink not permitted; COPIED $Src -> $Dst (edits not live; enable Developer Mode + re-run)"
  }
}

# Copy rather than symlink, for settings.json: the app rewrites it in place (/model
# persists to it) and a symlink would push that churn back into the repo.
function Copy-Config {
  param(
    [Parameter(Mandatory)] [string] $Src,
    [Parameter(Mandatory)] [string] $Dst
  )
  if (-not (Test-Path -LiteralPath $Src)) { Warn "source missing, skipping: $Src"; return }
  $parent = Split-Path -Parent $Dst
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }

  $existing = Get-Item -LiteralPath $Dst -Force -ErrorAction SilentlyContinue
  if ($existing) {
    if ($existing.LinkType) {
      Remove-Item -LiteralPath $Dst -Force   # old symlink into the repo — no data to keep
    } else {
      $backup = "$Dst.bak." + (Get-Date -Format 'yyyyMMddHHmmss')
      Move-Item -LiteralPath $Dst -Destination $backup
      Warn "backed up existing $Dst -> $backup"
    }
  }
  Copy-Item -LiteralPath $Src -Destination $Dst -Force
  Info "copied $Dst <- $Src"
}

function Expand-Dst([string] $p, [string] $ProfilePath) {
  # .Replace() is literal, not regex, so backslashes and braces stay as typed.
  $p = $p.Replace('{CONFIG}',       (Join-Path $env:USERPROFILE '.config'))
  $p = $p.Replace('{LOCALAPPDATA}', $env:LOCALAPPDATA)
  $p = $p.Replace('{APPDATA}',      $env:APPDATA)
  $p = $p.Replace('{CLAUDE}',       (Join-Path $env:USERPROFILE '.claude'))
  $p = $p.Replace('{PROFILE}',      $ProfilePath)
  $p = $p.Replace('{HOME}',         $env:USERPROFILE)
  return $p.Replace('/', '\')
}

# links.tsv drives this: windows_dst "-" skips, type `copy` seeds a file the app then owns.
function Invoke-Links([string] $ProfilePath) {
  Info "Linking config files…"
  foreach ($row in Read-Links) {
    if ($row.windows_dst -eq '-') { continue }
    $src = Join-Path $DOT ($row.src -replace '/', '\')
    $dst = Expand-Dst $row.windows_dst $ProfilePath
    if     ($row.type -eq 'dir')  { Link-Config $src $dst -Directory }
    elseif ($row.type -eq 'copy') { Copy-Config $src $dst }
    else                          { Link-Config $src $dst }
  }
}

# --- scoop + per-tool setup ------------------------------------------------
function Ensure-Scoop {
  Info "Ensuring scoop is installed…"
  if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression
  }
  $env:Path = (Join-Path $env:USERPROFILE 'scoop\shims') + ';' + $env:Path
  # versions carries wezterm-nightly (extras only has the frozen 20240203 stable), and
  # without that bucket `scoop install` aborts the whole app list on a missing manifest.
  Info "Adding scoop buckets (extras, versions, nerd-fonts)…"
  foreach ($b in 'extras', 'versions', 'nerd-fonts') { scoop bucket add $b 2>$null }
}

# A stale winget/MSI Neovim under C:\Program Files sits ahead of scoop's shims in the
# machine PATH and breaks startup; removing it needs an admin shell, so only warn.
function Test-NvimShadow {
  $nvimCmd = Get-Command nvim -ErrorAction SilentlyContinue
  if (-not $nvimCmd) { return }
  $ver = (& $nvimCmd.Source --version | Select-Object -First 1)
  $shadowed = $nvimCmd.Source -notlike '*\scoop\*'
  $tooOld   = $ver -match 'v0\.(\d+)\.' -and [int]$Matches[1] -lt 12
  if ($shadowed -or $tooOld) {
    Warn "Active nvim is '$($nvimCmd.Source)' ($ver) — not the scoop 0.12+ build."
    Warn "The nvim config needs 0.12+. Remove the shadowing install in an ADMIN shell:"
    Warn "    winget uninstall --id Neovim.Neovim"
    Warn "Then restart your shell so scoop's nvim takes over."
  } else {
    Info "nvim OK: $($nvimCmd.Source) ($ver)"
  }
}

# Two stale copies shadow the nightly: scoop's plain `wezterm` app fights it over the same
# shims, and a machine-wide MSI owns the Start-menu shortcut (removing it needs admin).
function Test-WeztermShadow {
  $stale = $false
  if (Test-Path (Join-Path $env:USERPROFILE 'scoop\apps\wezterm')) {
    Warn "scoop's stable 'wezterm' app is installed — it fights wezterm-nightly over the same shims."
    Warn "    scoop uninstall wezterm"
    $stale = $true
  }
  if (Test-Path 'C:\Program Files\WezTerm\wezterm-gui.exe') {
    Warn "A machine-wide WezTerm MSI is installed; it owns the Start-menu shortcut."
    Warn "Remove it in an ADMIN shell (or via Settings -> Apps), then restart your shell:"
    Warn "    winget uninstall --id wez.wezterm"
    $stale = $true
  }
  if (-not $stale) {
    $wt = Get-Command wezterm -ErrorAction SilentlyContinue
    if ($wt) { Info "wezterm OK: $($wt.Source) ($(& $wt.Source --version))" }
  }
}

# --- GUI editors -------------------------------------------------------------
# Zed comes from scoop ($SCOOP_APPS), so install/update handle it with the CLI tools.
# VS Code has no user-scope scoop build, so it comes from winget instead and self-updates.
function Install-VSCode {
  if (Get-Command code -ErrorAction SilentlyContinue) {
    Info "VS Code already installed ($(code --version 2>$null | Select-Object -First 1)); it self-updates."
  } elseif (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Warn "winget not found. Install 'App Installer' from the Microsoft Store, or get VS Code from https://code.visualstudio.com/download"
  } else {
    Info "Installing VS Code via winget (user scope, no admin)…"
    winget install --id Microsoft.VisualStudioCode --scope user `
      --accept-package-agreements --accept-source-agreements
    # The installer adds `code` to PATH for NEW shells; prepend it here so extensions work now.
    $env:Path = (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin') + ';' + $env:Path
  }
}

# The extensions the VS Code config needs, one id per line in vscode\extensions.txt
# (trailing `# comments` allowed). --force makes --install-extension idempotent, so this
# runs on both install and update and picks up new lines in the file.
function Install-VSCodeExtensions {
  $extensions = Get-Content (Join-Path $DOT 'vscode\extensions.txt') |
    ForEach-Object { ($_ -split '#')[0].Trim() } |
    Where-Object { $_ }
  if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    Warn "'code' not on PATH — open a NEW shell and re-run install to add: $($extensions -join ', ')"
    return
  }
  foreach ($ext in $extensions) {
    Info "Installing VS Code extension $ext…"
    try { code --install-extension $ext --force }
    catch { Warn "could not install $ext ($_); install it from the Extensions view" }
  }
}

# Ask pwsh itself: OneDrive-redirection-aware and version-correct (PowerShell, not 5.1).
function Resolve-ProfilePath {
  $p = $null
  if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    $p = (& pwsh -NoProfile -Command '$PROFILE.CurrentUserAllHosts').Trim()
  }
  if (-not $p) {
    $p = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    Warn "could not resolve pwsh profile path; defaulting to $p"
  }
  return $p
}
