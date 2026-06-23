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

# ---- File-listing colors (Get-ChildItem) ----
# PowerShell 7's default $PSStyle.FileInfo.Directory is a blue *background*
# (ESC[44;1m), which renders as ugly solid bars behind folder names. Switch
# directories, symlinks, and executables to plain Tokyo Night foreground colors.
if ($PSStyle) {
  $PSStyle.FileInfo.Directory    = $PSStyle.Bold + $PSStyle.Foreground.FromRgb(0x7aa2f7)  # blue
  $PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.FromRgb(0x7dcfff)                   # cyan
  $PSStyle.FileInfo.Executable   = $PSStyle.Foreground.FromRgb(0x9ece6a)                   # green
}

# ---- Aliases / functions ----
Set-Alias -Name zj -Value zellij
function ll { Get-ChildItem -Force @args }      # long listing incl. hidden
function la { Get-ChildItem -Force @args }
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# ---- Starship prompt (cached init) ----
# `starship init` spawns the binary and regenerates the same script every launch
# (~180ms). Cache it to disk and dot-source the cache; only re-run when the
# starship binary is newer than the cache (i.e. after an upgrade).
$starshipExe = (Get-Command starship -ErrorAction SilentlyContinue)?.Source
if ($starshipExe) {
  $starshipCache = Join-Path ([IO.Path]::GetTempPath()) 'starship_init.ps1'
  if (-not (Test-Path $starshipCache) -or
      (Get-Item $starshipExe).LastWriteTime -gt (Get-Item $starshipCache).LastWriteTime) {
    &$starshipExe init powershell | Out-File -Encoding utf8 $starshipCache
  }
  . $starshipCache
}

# ---- Zellij auto-start (only inside WezTerm, interactive, not nested) ----
# Mirrors the .zshrc guard. PowerShell isn't a supported target for
# `zellij setup --generate-auto-start`, so we attach-or-create manually and
# exit pwsh when Zellij detaches (== ZELLIJ_AUTO_EXIT).
if ($Host.Name -eq 'ConsoleHost' -and
    -not $env:ZELLIJ -and
    $env:WEZTERM_PANE -and
    (Get-Command zellij -ErrorAction SilentlyContinue)) {
  # Zellij doesn't inherit the parent pwsh on Windows; with no default_shell set
  # it falls back to the OS default (cmd.exe). Point it at pwsh via $SHELL, which
  # Zellij reads for its default shell. (Linux already has $SHELL = zsh.)
  $env:SHELL = (Get-Command pwsh).Source
  zellij attach --create main   # attach-or-create the "main" session (named: documented form)
  # Only close the shell if Zellij exited cleanly (you detached/quit on purpose).
  # On any failure, fall through to an interactive prompt instead of trapping the
  # window in an open-then-immediately-close loop.
  if ($LASTEXITCODE -eq 0) { exit }
}
