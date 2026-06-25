# Dotfiles installer for Windows (WezTerm + Zellij + PowerShell 7 + Starship + Neovim).
# Counterpart of install.sh. Idempotent: safe to re-run. Existing files are
# backed up before linking. Shares the wezterm/zellij/starship/nvim/ideavim
# configs with Linux; only the shell config differs (pwsh/profile.ps1).
#
# FIRST RUN (pwsh 7 isn't installed yet) — run under Windows PowerShell 5.1:
#   powershell -ExecutionPolicy Bypass -File install.ps1
#
# Uses scoop (user-scope, no admin). For live-editable config links, enable
# Windows "Developer Mode" (Settings -> System -> For developers) once so file
# symlinks can be created unprivileged; otherwise the installer copies instead.

$ErrorActionPreference = 'Stop'
$DOT = $PSScriptRoot

function Info($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Host "!!  $msg" -ForegroundColor Yellow }

# ---------------------------------------------------------------------------
# Link a repo file (symlink) or directory (junction) to a target path.
# Junctions need no privilege; file symlinks need Developer Mode or admin, so
# they fall back to a plain copy (with a warning) when not permitted.
function Link-Config {
  param(
    [Parameter(Mandatory)] [string] $Src,
    [Parameter(Mandatory)] [string] $Dst,
    [switch] $Directory
  )
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

# ---------------------------------------------------------------------------
# Allow the installed profile (and this script on later runs) to load.
Info "Setting ExecutionPolicy (CurrentUser -> RemoteSigned)…"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# ---------------------------------------------------------------------------
Info "Ensuring scoop is installed…"
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression
}
# Make sure scoop shims are on PATH for the rest of this session.
$env:Path = (Join-Path $env:USERPROFILE 'scoop\shims') + ';' + $env:Path

Info "Adding scoop buckets (extras, nerd-fonts)…"
foreach ($b in 'extras', 'nerd-fonts') { scoop bucket add $b 2>$null }

# ---------------------------------------------------------------------------
# pwsh        — PowerShell 7 (the target shell)
# neovim/starship/wezterm — core stack
# zig         — C compiler nvim-treesitter uses to build parsers on Windows
# ripgrep/fd  — power Telescope (live grep / find files)
# fzf         — fuzzy finder
# win32yank   — Neovim clipboard provider (auto-detected for clipboard=unnamedplus)
# zellij      — scoop ships the native Windows (ConPTY) build; avoids the winget
#               version-numbering bug. Fallback: github.com/zellij-org/zellij/releases
# zoxide      — smarter cd (`z`/`zi`); `zi` uses fzf (also installed above)
# JetBrainsMono-NF — Nerd Font for prompt/multiplexer glyphs
Info "Installing packages via scoop…"
$pkgs = @('pwsh', 'neovim', 'starship', 'wezterm', 'zig', 'ripgrep', 'fd', 'fzf',
          'win32yank', 'zellij', 'zoxide', 'JetBrainsMono-NF')
scoop install @pkgs

# ---------------------------------------------------------------------------
# Resolve the pwsh 7 profile path from pwsh itself — OneDrive-redirection-aware
# and version-correct (…\PowerShell\… not 5.1's …\WindowsPowerShell\…).
$profilePath = $null
if (Get-Command pwsh -ErrorAction SilentlyContinue) {
  $profilePath = (& pwsh -NoProfile -Command '$PROFILE.CurrentUserAllHosts').Trim()
}
if (-not $profilePath) {
  $profilePath = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
  Warn "could not resolve pwsh profile path; defaulting to $profilePath"
}

# ---------------------------------------------------------------------------
Info "Linking config files…"
$cfg = Join-Path $env:USERPROFILE '.config'
Link-Config (Join-Path $DOT 'wezterm\wezterm.lua')    (Join-Path $cfg 'wezterm\wezterm.lua')
Link-Config (Join-Path $DOT 'starship\starship.toml') (Join-Path $cfg 'starship.toml')
# Zellij on Windows reads %APPDATA%\zellij (Roaming), not ~/.config/zellij.
Link-Config (Join-Path $DOT 'zellij\config.kdl')      (Join-Path $env:APPDATA 'zellij\config.kdl')
Link-Config (Join-Path $DOT 'intellij\.ideavimrc')    (Join-Path $env:USERPROFILE '.ideavimrc')
# Neovim on Windows reads %LOCALAPPDATA%\nvim.
Link-Config (Join-Path $DOT 'nvim')                   (Join-Path $env:LOCALAPPDATA 'nvim') -Directory
Link-Config (Join-Path $DOT 'pwsh\profile.ps1')       $profilePath
# Claude Code — settings.json carries the status-line pointer; statusline.js is
# the actual config. Linking settings.json means /config edits land in the repo.
$claude = Join-Path $env:USERPROFILE '.claude'
Link-Config (Join-Path $DOT 'claude\statusline.js')   (Join-Path $claude 'statusline.js')
Link-Config (Join-Path $DOT 'claude\settings.json')   (Join-Path $claude 'settings.json')

# ---------------------------------------------------------------------------
Info "Done. Open WezTerm to start using the new setup."
Info "It launches pwsh, auto-starts Zellij, and shows the Starship prompt."
Warn "If configs were COPIED (not linked), enable Developer Mode and re-run for live edits."
