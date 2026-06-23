# PowerShell 7 profile — managed by dotfiles (linked by install.ps1).
# Windows counterpart of zsh/.zshrc. Linked to $PROFILE.CurrentUserAllHosts.
#
# zsh feature            -> PowerShell equivalent
#   autosuggestions      -> PSReadLine -PredictionSource History (inline ghost text)
#   syntax-highlighting  -> PSReadLine inline command coloring (built in)
#   history dedup/search -> PSReadLine options + HistorySearch key handlers
#   aliases / functions  -> Set-Alias / functions
#   starship             -> starship init powershell
#   zellij auto-start     -> guarded block at the bottom

# ---- Editor ----
$env:EDITOR = 'nvim'

# ---- PSReadLine: history, prediction, syntax highlighting, keybindings ----
Import-Module PSReadLine -ErrorAction SilentlyContinue
if (Get-Module PSReadLine) {
  Set-PSReadLineOption -EditMode Emacs
  Set-PSReadLineOption -HistoryNoDuplicates
  Set-PSReadLineOption -MaximumHistoryCount 50000
  Set-PSReadLineOption -HistorySearchCursorMovesToEnd
  # Inline suggestion from history (== zsh-autosuggestions ghost text).
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle InlineView

  # Up/Down do prefix history search (matches the .zshrc bindkeys).
  Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
  # Tab opens a completion menu (== zsh `menu select`).
  Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
}

# ---- Aliases / functions ----
Set-Alias -Name zj -Value zellij
function ll { Get-ChildItem -Force @args }      # long listing incl. hidden
function la { Get-ChildItem -Force @args }
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# ---- Starship prompt ----
if (Get-Command starship -ErrorAction SilentlyContinue) {
  Invoke-Expression (&starship init powershell)
}

# ---- Zellij auto-start (only inside WezTerm, interactive, not nested) ----
# Mirrors the .zshrc guard. PowerShell isn't a supported target for
# `zellij setup --generate-auto-start`, so we attach-or-create manually and
# exit pwsh when Zellij detaches (== ZELLIJ_AUTO_EXIT).
if ($Host.Name -eq 'ConsoleHost' -and
    -not $env:ZELLIJ -and
    $env:WEZTERM_PANE -and
    (Get-Command zellij -ErrorAction SilentlyContinue)) {
  zellij attach --create main   # attach-or-create the "main" session (named: documented form)
  # Only close the shell if Zellij exited cleanly (you detached/quit on purpose).
  # On any failure, fall through to an interactive prompt instead of trapping the
  # window in an open-then-immediately-close loop.
  if ($LASTEXITCODE -eq 0) { exit }
}
