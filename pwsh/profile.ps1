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
  # One splat instead of six separate Set-PSReadLineOption calls. NOTE: splatting
  # needs a $variable + the @ operator (`@psrlOpts`); a bare `@{...}` literal is
  # passed as a positional arg and errors.
  #   PredictionSource/ViewStyle == zsh-autosuggestions inline ghost text.
  $psrlOpts = @{
    EditMode                      = 'Vi'   # modal editing (Esc -> normal mode); matches zsh `bindkey -v`.
                                           # Mode is shown in the prompt via starship's vimcmd_symbol;
                                           # don't set -ViModeIndicator here, starship's init overrides it.
    HistoryNoDuplicates           = $true
    MaximumHistoryCount           = 50000
    HistorySearchCursorMovesToEnd = $true
    PredictionSource              = 'History'
    PredictionViewStyle           = 'InlineView'
  }
  Set-PSReadLineOption @psrlOpts

  # Up/Down do prefix history search (matches the .zshrc bindkeys).
  Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
  # Tab opens a completion menu (== zsh `menu select`).
  Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
  # Accept the inline prediction without the arrow keys (works in Vi insert mode,
  # since these aren't vi-motion keys). `End` already accepts the whole suggestion
  # by default; Ctrl+e is added so the key matches the zsh binding (end-of-line),
  # and Ctrl+f accepts just the next word. Mirrors the bindkeys in .zshrc.
  Set-PSReadLineKeyHandler -Key Ctrl+e    -Function AcceptSuggestion
  Set-PSReadLineKeyHandler -Key Ctrl+f    -Function AcceptNextSuggestionWord
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
function ll { Get-ChildItem -Force @args }         # long listing incl. hidden (== zsh `ls -lah`)
function la { Get-ChildItem -Force -Name @args }   # names only, incl. hidden (== zsh `ls -A`)
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# ---- Cached tool init (starship, zoxide) ----
# `<tool> init powershell` spawns the binary and regenerates the same script every
# launch (starship alone is ~180ms). Cache it to disk and dot-source the cache;
# only re-run when the binary is newer than the cache (i.e. after an upgrade).
function Initialize-Cached {
  param(
    [Parameter(Mandatory)] [string] $Name,
    [string[]] $InitArgs = @('init', 'powershell'),
    [switch] $Force   # regenerate even if the cache exists (after a binary upgrade)
  )
  $cache = Join-Path ([IO.Path]::GetTempPath()) "${Name}_init.ps1"
  # Warm path: cache already exists -> dot-source it straight away. We deliberately
  # skip the old `Get-Command` + LastWriteTime freshness check here: that PATH scan
  # cost ~25ms *every* launch just to detect the rare case of a tool upgrade. Instead
  # the cache is treated as durable; refresh it explicitly with `Update-ShellCache`
  # (or per-tool `Initialize-Cached <name> -Force ...`) after upgrading starship/zoxide.
  if ((Test-Path $cache) -and -not $Force) { . $cache; return }
  # Cold/forced path: resolve the binary and (re)generate the cache.
  $exe = (Get-Command $Name -ErrorAction SilentlyContinue)?.Source
  if (-not $exe) { return }
  # Generate to a temp file first, then promote it only if the binary succeeded and
  # produced output. Writing straight to $cache would truncate it before the binary
  # runs, so a failed/killed init would leave an empty or partial cache that the warm
  # path then dot-sources on every future launch — silently breaking the prompt until
  # a manual Update-ShellCache. The temp+move also avoids two parallel launches
  # interleaving writes to the same cache file.
  $tmp = "$cache.$PID.tmp"
  & $exe @InitArgs | Out-File -Encoding utf8 $tmp
  if ($LASTEXITCODE -eq 0 -and (Test-Path $tmp) -and (Get-Item $tmp).Length -gt 0) {
    Move-Item -Force $tmp $cache
    . $cache
  } else {
    Remove-Item $tmp -ErrorAction SilentlyContinue
  }
}

# Force-refresh every cached tool init. Run this once after upgrading starship/zoxide
# (e.g. via scoop/winget) so the cached prompt code picks up the new binary's output.
function Update-ShellCache {
  Initialize-Cached starship -Force -InitArgs 'init','powershell','--print-full-init'
  Initialize-Cached zoxide   -Force
  Write-Host 'Shell init caches refreshed.' -ForegroundColor Green
}

# Starship prompt. Use --print-full-init: plain `init powershell` only emits a
# stub that re-spawns starship.exe at load time, so caching it caches nothing
# (the binary still runs every tab, ~340ms). --print-full-init emits the real
# prompt code, which dot-sources from disk in ~85ms with no subprocess.
Initialize-Cached starship -InitArgs 'init','powershell','--print-full-init'
# zoxide — smarter cd. `z <dir>` jumps to the most "frecent" match, `zi` picks
# interactively (needs fzf, which the installer provides). Init AFTER starship so
# zoxide's prompt hook wraps starship's prompt rather than being overwritten by it.
Initialize-Cached zoxide

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
