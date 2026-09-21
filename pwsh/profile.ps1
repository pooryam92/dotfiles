# PowerShell 7 profile — managed by dotfiles, linked to $PROFILE.CurrentUserAllHosts.

# ---- Editor ----
$env:EDITOR = 'nvim'

# ---- PSReadLine: emacs editing, history, inline prediction, keybindings ----
if (Get-Module PSReadLine) {
  $psrlOpts = @{
    EditMode                      = 'Emacs'       # always-on editing keys, no modes
    HistoryNoDuplicates           = $true
    MaximumHistoryCount           = 50000
    HistorySearchCursorMovesToEnd = $true
    PredictionSource              = 'History'     # zsh-autosuggestions-style inline ghost text
    PredictionViewStyle           = 'InlineView'
  }
  Set-PSReadLineOption @psrlOpts

  Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
  Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
  # Ctrl+e accepts the whole suggestion only when the cursor is at end of line,
  # otherwise it is plain end-of-line. Ctrl+f is left as emacs forward-char.
  Set-PSReadLineKeyHandler -Key Ctrl+e -ScriptBlock {
    $line = $null; $cursor = 0
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($cursor -eq $line.Length) { [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion($null, $null) }
    else                          { [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine($null, $null) }
  }
  Set-PSReadLineKeyHandler -Key Alt+f  -Function AcceptNextSuggestionWord
  Set-PSReadLineKeyHandler -Chord 'Ctrl+x,Ctrl+e' -Function ViEditVisually
  Set-PSReadLineKeyHandler -Key Alt+.     -Function YankLastArg

  # A leading space keeps a command out of history. The handler is chained, not
  # replaced, so PSReadLine's sensitive-data filter still runs.
  $defaultAddToHistory = (Get-PSReadLineOption).AddToHistoryHandler
  Set-PSReadLineOption -AddToHistoryHandler ({
    param($line)
    if ($line -and $line[0] -eq ' ') { return $false }
    if ($defaultAddToHistory) { return $defaultAddToHistory.Invoke($line) }
    return $true
  }.GetNewClosure())
}

# ---- Native prompt (no subprocess, ~2ms) ----
# The branch is read straight from .git/HEAD instead of spawning git on every draw.
# Inside a worktree .git is a file holding "gitdir: <path>", which may be relative.
function prompt {
  $ok = $?
  $path = $PWD.Path
  if ($path.StartsWith($HOME, [System.StringComparison]::OrdinalIgnoreCase)) {
    $path = '~' + $path.Substring($HOME.Length)
  }

  $branch = ''
  $dir = $PWD.Path
  while ($dir) {
    $gitPath = Join-Path $dir '.git'
    $gitDir  = $null
    if (Test-Path -LiteralPath $gitPath -PathType Container) {
      $gitDir = $gitPath                                        # plain repo
    }
    elseif (Test-Path -LiteralPath $gitPath -PathType Leaf) {
      # -is [string] guards an empty or odd file: the prompt must never throw.
      $line = Get-Content -LiteralPath $gitPath -TotalCount 1 -ErrorAction SilentlyContinue
      if ($line -is [string] -and $line.Trim() -like 'gitdir: *') {
        $gitDir = $line.Trim().Substring(8)
        if (-not [System.IO.Path]::IsPathRooted($gitDir)) {      # the path may be relative
          $gitDir = Join-Path $dir $gitDir
        }
      }
    }
    if ($gitDir) {
      $head = Join-Path $gitDir 'HEAD'
      if (Test-Path -LiteralPath $head) {
        $ref = (Get-Content -LiteralPath $head -Raw).Trim()
        $branch = if ($ref -like 'ref: refs/heads/*') { $ref.Substring(16) }
                  elseif ($ref)                        { $ref.Substring(0, [Math]::Min(7, $ref.Length)) }
                  else                                 { '' }
        break
      }
    }
    $parent = Split-Path $dir -Parent
    if ($parent -eq $dir) { break }
    $dir = $parent
  }

  $e = [char]27
  $dirPart  = "$e[34m$path$e[0m"
  $gitPart  = if ($branch) { " $e[36m$branch$e[0m" } else { '' }
  $markPart = if ($ok)     { "$e[32m>$e[0m" }       else { "$e[31m>$e[0m" }
  "$dirPart$gitPart`n$markPart "
}

# ---- File-listing colors (Get-ChildItem) ----
# Tokyo Night colors; also replaces PS7's blue-background directories.
if ($PSStyle) {
  $PSStyle.FileInfo.Directory    = $PSStyle.Bold + $PSStyle.Foreground.FromRgb(0x7aa2f7)  # blue
  $PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.FromRgb(0x7dcfff)                   # cyan
  $PSStyle.FileInfo.Executable   = $PSStyle.Foreground.FromRgb(0x9ece6a)                   # green
}

# ---- Aliases / functions ----
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force -Name @args }
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# ---- fzf + fd + bat: fuzzy file/dir pickers ----
# Hand-rolled, not PSFzf: shells out to fzf only on keypress, so startup stays instant.
if ((Get-Module PSReadLine) -and
    (Get-Command fzf -ErrorAction SilentlyContinue) -and
    (Get-Command fd  -ErrorAction SilentlyContinue)) {
  Set-PSReadLineKeyHandler -Key Ctrl+t -ScriptBlock {
    $fzfArgs = @('--height', '40%', '--reverse')
    if (Get-Command bat -ErrorAction SilentlyContinue) {
      $fzfArgs += @('--preview', 'bat --color=always --style=numbers --line-range=:200 {}')
    }
    $sel = fd --type f --hidden --exclude .git | fzf @fzfArgs
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()   # fzf scrolled the screen; redraw
    if ($sel) { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($sel) }
  }
  Set-PSReadLineKeyHandler -Key Alt+c -ScriptBlock {
    $sel = fd --type d --hidden --exclude .git | fzf --height 40% --reverse
    if ($sel) { Set-Location $sel }
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
  }
}

# ---- zoxide (smarter cd) ----
# `zoxide init` spawns the binary, so its output is cached to disk and dot-sourced.
# `install.ps1 update` deletes the cache so the next shell regenerates it.
$zoxideCache = Join-Path ([IO.Path]::GetTempPath()) 'zoxide_init.ps1'
if (-not (Test-Path $zoxideCache)) {
  $zoxideExe = (Get-Command zoxide -ErrorAction SilentlyContinue)?.Source
  if ($zoxideExe) {
    # PID-tagged temp then promote, so a half-written cache never gets sourced.
    $tmp = "$zoxideCache.$PID.tmp"
    & $zoxideExe init powershell | Out-File -Encoding utf8 $tmp
    if ((Test-Path $tmp) -and (Get-Item $tmp).Length -gt 0) { Move-Item -Force $tmp $zoxideCache }
    else { Remove-Item $tmp -ErrorAction SilentlyContinue }
  }
}
if (Test-Path $zoxideCache) { . $zoxideCache }
