# Dotfiles installer for Windows (WezTerm + PowerShell 7 + Neovim).
# Counterpart of install.sh. Idempotent: safe to re-run. Existing files are backed up
# before linking. The managed apps live in setup\tools.tsv (+ a base list in lib.ps1)
# and the config-link targets in setup\links.tsv; shared actions/helpers in setup\lib.ps1.
#
# FIRST RUN (pwsh 7 isn't installed yet) — run under Windows PowerShell 5.1:
#   powershell -ExecutionPolicy Bypass -File install.ps1
#
# Uses scoop (user-scope, no admin). For live-editable config links, enable Windows
# "Developer Mode" (Settings -> System -> For developers) once so file symlinks can be
# created unprivileged; otherwise the installer copies instead.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'setup\lib.ps1')

# Allow the installed profile (and this script on later runs) to load.
Info "Setting ExecutionPolicy (CurrentUser -> RemoteSigned)…"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# --- packages --------------------------------------------------------------
Ensure-Scoop
# Base apps + every tool's scoop id (from tools.tsv). neovim needs 0.12+ (vim.pack);
# a separate winget/MSI Neovim shadows scoop on PATH — the guard below warns if so.
# NOTE: the nvim config is colorscheme-only (no treesitter/Telescope), so zig, the
# tree-sitter CLI, ripgrep and fd are intentionally NOT installed — add them back if
# you grow the nvim config (see docs/nvim.md). install.sh mirrors this.
Info "Installing packages via scoop…"
scoop install @(Get-ScoopApps)

# Claude Code — Anthropic's CLI. Not a scoop app; the official installer self-updates
# afterwards (or .\update.ps1), so only run it when absent. Config linked below.
Info "Installing Claude Code…"
if (Get-Command claude -ErrorAction SilentlyContinue) {
  Info "claude already installed ($(claude --version 2>$null))"
} else {
  try { Invoke-RestMethod -Uri 'https://claude.ai/install.ps1' | Invoke-Expression }
  catch { Warn "Claude Code install failed ($_). See https://docs.anthropic.com/en/docs/claude-code" }
}

Test-NvimShadow

# --- config links ----------------------------------------------------------
# Resolve the pwsh profile path first ({PROFILE} token feeds Invoke-Links).
$profilePath = Resolve-ProfilePath
Invoke-Links $profilePath

# ---------------------------------------------------------------------------
Info "Done. Open WezTerm to start using the new setup."
Info "It launches pwsh with the native prompt; Alt+\\ splits, Ctrl+p = pane mode."
Warn "If configs were COPIED (not linked), enable Developer Mode and re-run for live edits."
