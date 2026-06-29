# PowerShell 7 profile — managed by dotfiles (linked by install.ps1).
# Windows counterpart of zsh/.zshrc. Linked to $PROFILE.CurrentUserAllHosts.
#
# zsh feature            -> PowerShell equivalent
#   autosuggestions      -> PSReadLine -PredictionSource History (inline ghost text)
#   syntax-highlighting  -> PSReadLine inline command coloring (built in)
#   history dedup/search -> PSReadLine options + HistorySearch key handlers
#   aliases / functions  -> Set-Alias / functions
#   starship             -> starship init powershell
# Multiplexing (panes/tabs) is handled by WezTerm itself (Alt chords + Ctrl+p/t
# modes), so there is no multiplexer auto-start here — see wezterm/wezterm.lua.

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

  # == zsh HIST_IGNORE_SPACE: a leading space keeps a command out of history.
  # Chain (not replace) the existing default handler so PSReadLine's built-in
  # sensitive-data filter (tokens/passwords -> never persisted) still runs.
  $defaultAddToHistory = (Get-PSReadLineOption).AddToHistoryHandler
  Set-PSReadLineOption -AddToHistoryHandler ({
    param($line)
    if ($line -and $line[0] -eq ' ') { return $false }
    if ($defaultAddToHistory) { return $defaultAddToHistory.Invoke($line) }
    return $true
  }.GetNewClosure())
}

# ---- File-listing colors (Get-ChildItem) ----
# Tokyo Night file-listing colors — the pwsh counterpart to zsh's `ls --color=auto`
# (blue dirs / cyan symlinks / green executables). This also overrides PowerShell
# 7's default $PSStyle.FileInfo.Directory, which is a blue *background* (ESC[44;1m)
# that renders as ugly solid bars behind folder names.
if ($PSStyle) {
  $PSStyle.FileInfo.Directory    = $PSStyle.Bold + $PSStyle.Foreground.FromRgb(0x7aa2f7)  # blue
  $PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.FromRgb(0x7dcfff)                   # cyan
  $PSStyle.FileInfo.Executable   = $PSStyle.Foreground.FromRgb(0x9ece6a)                   # green
}

# ---- Aliases / functions ----
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

# ---- fzf key-bindings (PSFzf) ----
# The pwsh counterpart to zsh's fzf bindings: Ctrl+R fuzzy history, Ctrl+T insert a
# file/dir path, Alt+C fuzzy-cd — the same three keys on both shells. PSFzf is
# installed by install.ps1 (Install-Module); guarded so the prompt still loads
# (with PSReadLine's plain Ctrl+R) if it's missing.
if (Get-Module -ListAvailable PSFzf) {
  Import-Module PSFzf
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
  # PSFzf has no built-in Alt+C chord; bind fuzzy-cd to match fzf's Alt-C, then
  # redraw the prompt so the new directory shows immediately.
  Set-PSReadLineKeyHandler -Key 'Alt+c' -ScriptBlock {
    Invoke-FuzzySetLocation
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
  }
}

# ---- Drills (spaced-repetition learning of this repo's own tools) ----
# Windows counterpart of the zsh drills block. `learn` runs a drill session; at
# startup, if any cards are due, print one line pointing at it (silent otherwise).
# drill.js lives in the repo and is run in place: resolve the repo root from this
# profile's real path — it's symlinked from the repo to $PROFILE, so the symlink
# target is <repo>/pwsh/profile.ps1 and its grandparent is the repo root. Guarded on
# node so a missing runtime is silent.
if (Get-Command node -ErrorAction SilentlyContinue) {
  $target = (Get-Item $PSCommandPath).ResolveLinkTarget($true)
  $drillRoot = if ($target) { $target.Directory.Parent.FullName }
               else { Split-Path -Parent (Split-Path -Parent $PSCommandPath) }
  $drillJs = Join-Path $drillRoot 'drills/drill.js'
  if (Test-Path $drillJs) {
    function learn { node $drillJs @args }
    $due = 0
    try { $due = [int](node $drillJs --count 2>$null) } catch { $due = 0 }
    if ($due -gt 0) {
      $word = if ($due -eq 1) { 'drill' } else { 'drills' }
      Write-Host "🎴 $due $word due — run " -NoNewline
      Write-Host 'learn' -ForegroundColor Yellow
    }
  }
}
