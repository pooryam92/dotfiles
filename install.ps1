# Dotfiles installer for Windows (WezTerm + PowerShell 7 + Starship + Neovim).
# Counterpart of install.sh. Idempotent: safe to re-run. Existing files are
# backed up before linking. Shares the wezterm/starship/nvim/ideavim configs
# with Linux; only the shell config differs (pwsh/profile.ps1).
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
# neovim      — needs 0.12+ (the nvim config uses vim.pack / PackChanged); scoop
#               ships current stable. A separate winget/MSI Neovim in
#               "C:\Program Files\Neovim" shadows scoop on PATH and breaks the
#               config — the post-install check below warns if that's the case.
# starship/wezterm — core stack
# fzf         — fuzzy finder; powers zoxide's `zi` and the PSFzf keys (below)
# win32yank   — Neovim clipboard provider (auto-detected for clipboard=unnamedplus)
# zoxide      — smarter cd (`z`/`zi`); `zi` uses fzf (also installed above)
# zed         — GUI editor counterpart to Neovim (extras bucket); self-updates
# JetBrainsMono-NF — Nerd Font for prompt glyphs
# NOTE: the nvim config is colorscheme-only (no treesitter/Telescope), so zig, the
# tree-sitter CLI, ripgrep and fd are intentionally NOT installed — add them back
# if you grow the nvim config (see docs/nvim.md). install.sh mirrors this.
Info "Installing packages via scoop…"
$pkgs = @('pwsh', 'neovim', 'starship', 'wezterm', 'fzf', 'win32yank',
          'zoxide', 'zed', 'python', 'JetBrainsMono-NF')
scoop install @pkgs

# ---------------------------------------------------------------------------
# PSFzf — PowerShell module that wires fzf into PSReadLine (Ctrl+r/Ctrl+t/Alt+c),
# matching zsh's fzf key-bindings. It's a PSGallery module, not a scoop app.
Info "Installing PSFzf module (fzf key-bindings for PSReadLine)…"
if (-not (Get-Module -ListAvailable PSFzf)) {
  try {
    if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
      Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }
    Install-Module PSFzf -Scope CurrentUser -Force -AllowClobber
  } catch {
    Warn "PSFzf install failed ($_). Fuzzy Ctrl+r/Ctrl+t/Alt+c stay off until: Install-Module PSFzf"
  }
}

# ---------------------------------------------------------------------------
# Claude Code — Anthropic's CLI. Not a scoop app; the official Windows installer
# self-updates afterwards (or .\update.ps1), so only run it when absent. Its
# config (settings.json, statusline.js) is linked from this repo below.
Info "Installing Claude Code…"
if (Get-Command claude -ErrorAction SilentlyContinue) {
  Info "claude already installed ($(claude --version 2>$null))"
} else {
  try { Invoke-RestMethod -Uri 'https://claude.ai/install.ps1' | Invoke-Expression }
  catch { Warn "Claude Code install failed ($_). See https://docs.anthropic.com/en/docs/claude-code" }
}

# ---------------------------------------------------------------------------
Info "Building the cheat tool's Python venv (Textual TUI)…"
# `cheat` is a Python + Textual app (tools\cheat-py\cheat.py). Textual lives in a
# dedicated venv (kept out of the system Python); the shell `cheat` wrapper prefers
# this interpreter and falls back to a system python (plain-text mode) without it.
# `keymap` (tools\keymap\keymap.py) shares this same venv, so one Textual install
# covers both TUIs.
$cheatVenv = Join-Path $env:USERPROFILE '.local\share\cheat\venv'
$cheatPy   = Join-Path $cheatVenv 'Scripts\python.exe'
$haveTextual = $false
if (Test-Path $cheatPy) { & $cheatPy -c 'import textual' 2>$null; $haveTextual = ($LASTEXITCODE -eq 0) }
if ($haveTextual) {
  Info "cheat venv already has Textual"
} else {
  python -m venv $cheatVenv
  & $cheatPy -m pip install -q --upgrade pip textual
  if ($LASTEXITCODE -ne 0) { Warn "Textual install failed; 'cheat' still works in plain-text mode" }
}

# ---------------------------------------------------------------------------
# Guard: the nvim config requires 0.12+ (vim.pack / PackChanged). scoop installs
# a current build, but a stale winget/MSI Neovim under "C:\Program Files\Neovim"
# sits in the machine PATH ahead of scoop's user shims and wins `nvim`, aborting
# startup with "Invalid 'event': 'PackChanged'". Detect and tell the user how to
# remove it (needs an elevated shell — this user-scope installer can't elevate).
$nvimCmd = Get-Command nvim -ErrorAction SilentlyContinue
if ($nvimCmd) {
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
Link-Config (Join-Path $DOT 'intellij\.ideavimrc')    (Join-Path $env:USERPROFILE '.ideavimrc')
# Neovim on Windows reads %LOCALAPPDATA%\nvim.
Link-Config (Join-Path $DOT 'nvim')                   (Join-Path $env:LOCALAPPDATA 'nvim') -Directory
# Zed on Windows reads %APPDATA%\Zed (Roaming), not ~/.config/zed.
Link-Config (Join-Path $DOT 'zed\settings.json')      (Join-Path $env:APPDATA 'Zed\settings.json')
Link-Config (Join-Path $DOT 'zed\keymap.json')        (Join-Path $env:APPDATA 'Zed\keymap.json')
# The `cheat` command: one implementation (tools\cheat-py\cheat.py — Python + Textual,
# launched from both shells) plus its data — entries (cheat.tsv) and category index /
# learning order (cheat-index.tsv). All three are linked together so cheat.py finds
# its siblings; Textual lives in the venv built above.
Link-Config (Join-Path $DOT 'tools\cheat-py\cheat.py')        (Join-Path $cfg 'cheat.py')
Link-Config (Join-Path $DOT 'tools\cheat-py\cheat.tsv')       (Join-Path $cfg 'cheat.tsv')
Link-Config (Join-Path $DOT 'tools\cheat-py\cheat-index.tsv') (Join-Path $cfg 'cheat-index.tsv')
# The `keymap` command: a single Python file that reads your shell history into a
# usage heatmap. Reuses cheat's Textual venv above, so only the script is linked.
Link-Config (Join-Path $DOT 'tools\keymap\keymap.py')         (Join-Path $cfg 'keymap.py')
# Both tools share the reusable two-pane TUI in tools\tui\ (content model + Textual
# browser). They import it by resolving their own symlink back into the repo, the
# same trick that finds cheat's data files — so the package needs no link of its own.
Link-Config (Join-Path $DOT 'pwsh\profile.ps1')       $profilePath
# Claude Code — settings.json carries the status-line pointer; statusline.js is
# the actual config. Linking settings.json means /config edits land in the repo.
# commands\ holds repo-managed slash commands (e.g. /keymap — the agent that turns
# keymap's data into proposed dotfiles tweaks).
$claude = Join-Path $env:USERPROFILE '.claude'
Link-Config (Join-Path $DOT 'claude\statusline.js')   (Join-Path $claude 'statusline.js')
Link-Config (Join-Path $DOT 'claude\settings.json')   (Join-Path $claude 'settings.json')
Link-Config (Join-Path $DOT 'claude\commands\keymap.md') (Join-Path $claude 'commands\keymap.md')

# ---------------------------------------------------------------------------
Info "Done. Open WezTerm to start using the new setup."
Info "It launches pwsh with the Starship prompt; Alt+\\ splits, Ctrl+p = pane mode."
Warn "If configs were COPIED (not linked), enable Developer Mode and re-run for live edits."
