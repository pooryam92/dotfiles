# Shared helpers for install.ps1 (and the standalone zed installer) — dot-sourced,
# never run directly. Holds logging, the link helper, the scoop app list, and the
# per-tool setup steps. Which configs link where lives in links.tsv; this file holds
# the ACTIONS. Counterpart of lib.sh.

$LIB = $PSScriptRoot                       # …\setup — this lib + links.tsv live here
$DOT = Split-Path -Parent $LIB             # repo root — where the config sources live

# Everything installed (and updated) via scoop — mirrors the install_* calls in
# install.sh, minus Linux-only keyd (PowerToys covers remapping) and claude (native
# installer, not a scoop app). pwsh=target shell, fzf=fuzzy finder (Ctrl+T, zoxide
# `zi`), win32yank=Neovim clipboard provider.
$SCOOP_APPS = @('pwsh', 'fzf', 'win32yank',
                'wezterm-nightly', 'zoxide', 'fd', 'ripgrep', 'bat',
                'neovim', 'JetBrainsMono-NF')

function Info($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Host "!!  $msg" -ForegroundColor Yellow }

# --- config links (links.tsv) ------------------------------------------------
function Read-Links { Import-Csv -Delimiter "`t" -Path (Join-Path $LIB 'links.tsv') }

# --- config links ----------------------------------------------------------
# Link a repo file (symlink) or directory (junction) to a target path. Junctions
# need no privilege; file symlinks need Developer Mode or admin, so they fall back to
# a plain copy (with a warning) when not permitted.
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
      # Already a link/junction — remove the reparse point only (never the target).
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

# Copy a repo file to a target (not a symlink), overwriting whatever is there but
# backing up a real existing file first. Used for settings.json: the app rewrites it
# in place (e.g. /model persists to it), and a symlink would push that churn back into
# the repo. A copy seeds our defaults, then lets the live file diverge locally.
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

# Expand the links.tsv destination tokens to real Windows paths. {PROFILE} is the
# dynamically-resolved pwsh profile path, passed in (see Resolve-ProfilePath).
function Expand-Dst([string] $p, [string] $ProfilePath) {
  # .Replace() is a literal find/replace — no regex on either side, so the path's
  # backslashes/colons and the token braces stay literal (unlike -replace).
  $p = $p.Replace('{CONFIG}',       (Join-Path $env:USERPROFILE '.config'))
  $p = $p.Replace('{LOCALAPPDATA}', $env:LOCALAPPDATA)
  $p = $p.Replace('{APPDATA}',      $env:APPDATA)
  $p = $p.Replace('{CLAUDE}',       (Join-Path $env:USERPROFILE '.claude'))
  $p = $p.Replace('{PROFILE}',      $ProfilePath)
  $p = $p.Replace('{HOME}',         $env:USERPROFILE)
  return $p.Replace('/', '\')
}

# Link every config in links.tsv (windows_dst column; "-" means skip on Windows).
# The `type` column picks the strategy: dir/file symlink live, `copy` seeds a file the
# app owns afterward (claude's settings.json — kept a copy so /model edits don't churn
# the repo).
function Invoke-Links([string] $ProfilePath) {
  Info "Linking config files…"
  foreach ($row in Read-Links) {
    if ($row.windows_dst -eq '-') { continue }   # not linked on Windows (e.g. .zshrc)
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
  # Make sure scoop shims are on PATH for the rest of this session.
  $env:Path = (Join-Path $env:USERPROFILE 'scoop\shims') + ';' + $env:Path
  Info "Adding scoop buckets (extras, nerd-fonts)…"
  foreach ($b in 'extras', 'nerd-fonts') { scoop bucket add $b 2>$null }
}

# Guard: the nvim config needs 0.12+ (vim.pack / PackChanged). scoop installs a
# current build, but a stale winget/MSI Neovim under "C:\Program Files\Neovim" sits in
# the machine PATH ahead of scoop's user shims and wins `nvim`, aborting startup with
# "Invalid 'event': 'PackChanged'". Detect and tell the user how to remove it (needs
# an elevated shell — this user-scope installer can't elevate).
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

# Resolve the pwsh 7 profile path from pwsh itself — OneDrive-redirection-aware and
# version-correct (…\PowerShell\… not 5.1's …\WindowsPowerShell\…).
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
