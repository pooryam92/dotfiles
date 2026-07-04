# Dotfiles front door for Windows — installs AND updates the terminal/CLI stack
# (WezTerm + PowerShell 7 + Neovim + zoxide + Claude Code + font). Counterpart of
# install.sh. Idempotent: safe to re-run. Existing files are backed up before linking.
# The managed apps are the $SCOOP_APPS list in setup\lib.ps1, the config-link targets
# live in setup\links.tsv, and shared actions/helpers in setup\lib.ps1.
#
#   .\install.ps1              install everything (default; idempotent, safe to re-run)
#   .\install.ps1 update       force every managed app to its latest release
#
# Install is install-once (`scoop install` no-ops on apps already present), so re-running
# `install` never upgrades anything — that's what `update` is for. scoop is the native
# updater (`scoop status` shows what's behind); `update` just runs it on the managed apps.
#
# FIRST RUN (pwsh 7 isn't installed yet) — run under Windows PowerShell 5.1:
#   powershell -ExecutionPolicy Bypass -File install.ps1
#
# Uses scoop (user-scope, no admin). For live-editable config links, enable Windows
# "Developer Mode" (Settings -> System -> For developers) once so file symlinks can be
# created unprivileged; otherwise the installer copies instead.
param(
  [string] $Command = 'install'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'setup\lib.ps1')

# --- install ----------------------------------------------------------------
function Invoke-Install {
  # Allow the installed profile (and this script on later runs) to load.
  Info "Setting ExecutionPolicy (CurrentUser -> RemoteSigned)…"
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

  # --- packages ------------------------------------------------------------
  Ensure-Scoop
  # neovim needs 0.12+ (vim.pack);
  # a separate winget/MSI Neovim shadows scoop on PATH — the guard below warns if so.
  # NOTE: the nvim config is colorscheme-only (no treesitter/Telescope), so zig, the
  # tree-sitter CLI, ripgrep and fd are intentionally NOT installed — add them back if
  # you grow the nvim config (see nvim/README.md). install.sh mirrors this.
  Info "Installing packages via scoop…"
  scoop install @($SCOOP_APPS)

  # Claude Code — Anthropic's CLI. Not a scoop app; the official installer self-updates
  # afterwards (or `.\install.ps1 update`), so only run it when absent. Config linked below.
  Info "Installing Claude Code…"
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    Info "claude already installed ($(claude --version 2>$null))"
  } else {
    try { Invoke-RestMethod -Uri 'https://claude.ai/install.ps1' | Invoke-Expression }
    catch { Warn "Claude Code install failed ($_). See https://docs.anthropic.com/en/docs/claude-code" }
  }

  Test-NvimShadow

  # --- config links --------------------------------------------------------
  # Resolve the pwsh profile path first ({PROFILE} token feeds Invoke-Links).
  $profilePath = Resolve-ProfilePath
  Invoke-Links $profilePath

  # -------------------------------------------------------------------------
  Info "Done. Open WezTerm to start using the new setup."
  Info "It launches pwsh with the native prompt; Alt+\\ splits, Ctrl+p = pane mode."
  Warn "If configs were COPIED (not linked), enable Developer Mode and re-run for live edits."
}

# --- update -----------------------------------------------------------------
# (Config FILES are symlinks/junctions into this repo, so `git pull` already updates
# those; the commands below only touch the apps `install` installs via scoop.)

function Invoke-Update {
  if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) { Warn "scoop not found — run install first."; exit 1 }

  # scoop prints each app's old -> new transition as it upgrades. Scope to the apps
  # install manages ($SCOOP_APPS, not `scoop update *`) so we don't drag along
  # unrelated apps — mirrors install.sh's targeted apt upgrade.
  Info "Refreshing scoop manifests…"
  scoop update | Out-Null
  Info "Upgrading managed scoop apps to the latest…"
  scoop update @($SCOOP_APPS)

  # Bust the cached zoxide init. The profile caches `zoxide init` output to disk and
  # treats it as DURABLE (it never re-checks the binary), so an upgraded zoxide would
  # keep running the OLD init across restarts. Deleting the cache makes the next shell
  # regenerate it from the just-upgraded binary.
  $tmp = [IO.Path]::GetTempPath()
  Remove-Item (Join-Path $tmp 'zoxide_init.ps1') -Force -ErrorAction SilentlyContinue

  # Claude Code — native installer, self-updating. `claude update` forces it now.
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    Info "Updating Claude Code…"
    try { claude update } catch { Warn "claude update failed; it also self-updates on launch" }
  }

  # Neovim's plugins update separately, from inside nvim: :lua vim.pack.update()
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
