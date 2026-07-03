# PowerShell 7 profile — managed by dotfiles (linked by install.ps1).
# Windows counterpart of zsh/.zshrc. Linked to $PROFILE.CurrentUserAllHosts.
#
# Stripped to the bare minimum for speed (see repo goal #2). The old profile ran
# starship, which shelled out to starship.exe on EVERY prompt draw (~200ms of lag
# after each command) plus ~180ms at launch. This profile uses a native prompt
# function instead — no subprocess, ~2ms — so launches and every keystroke stay fast.
#
# NOTE (goal #3, deferred): zsh/.zshrc still uses starship on Pop!_OS, so the two
# shells look different for now. Mirror this native prompt into .zshrc when you want
# them identical again.

# ---- Editor ----
$env:EDITOR = 'nvim'

# ---- PSReadLine: emacs editing, history, inline prediction, keybindings ----
# PS7 auto-loads PSReadLine in interactive sessions, so this is the line editor we
# already have — configuring it is the whole keyboard experience (goal #1) and costs
# almost nothing on top. Keep it.
if (Get-Module PSReadLine) {
  $psrlOpts = @{
    EditMode                      = 'Emacs'       # always-on editing keys, no modes; matches zsh `bindkey -e`
    HistoryNoDuplicates           = $true
    MaximumHistoryCount           = 50000
    HistorySearchCursorMovesToEnd = $true
    PredictionSource              = 'History'     # zsh-autosuggestions-style inline ghost text
    PredictionViewStyle           = 'InlineView'
  }
  Set-PSReadLineOption @psrlOpts

  # Up/Down do prefix history search; Tab opens a completion menu (== zsh bindkeys).
  Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
  Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
  # Accept the inline prediction. Ctrl+e accepts the whole suggestion when one is
  # showing (cursor at end of line), otherwise just jumps to end of line — so it's
  # both "accept suggestion" and emacs end-of-line in one key. Alt+f accepts the next
  # word. Same keys as zsh; Ctrl+f stays its emacs default (ForwardChar / move right).
  Set-PSReadLineKeyHandler -Key Ctrl+e -ScriptBlock {
    $line = $null; $cursor = 0
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($cursor -eq $line.Length) { [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion($null, $null) }
    else                          { [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine($null, $null) }
  }
  Set-PSReadLineKeyHandler -Key Alt+f  -Function AcceptNextSuggestionWord
  # Ctrl+X Ctrl+E: edit the current command in $EDITOR (nvim), bash/readline-style.
  # Alt+.: insert the previous command's last argument. Both mirror zsh.
  Set-PSReadLineKeyHandler -Chord 'Ctrl+x,Ctrl+e' -Function ViEditVisually
  Set-PSReadLineKeyHandler -Key Alt+.     -Function YankLastArg

  # == zsh HIST_IGNORE_SPACE: a leading space keeps a command out of history. Chain
  # (not replace) the default handler so PSReadLine's sensitive-data filter still runs.
  $defaultAddToHistory = (Get-PSReadLineOption).AddToHistoryHandler
  Set-PSReadLineOption -AddToHistoryHandler ({
    param($line)
    if ($line -and $line[0] -eq ' ') { return $false }
    if ($defaultAddToHistory) { return $defaultAddToHistory.Invoke($line) }
    return $true
  }.GetNewClosure())
}

# ---- Native prompt (replaces starship — no subprocess, ~2ms) ----
# Shows a ~-abbreviated path, the current git branch, and a > that turns red after a
# failed command. The branch is read straight from .git/HEAD rather than shelling out
# to `git` on every draw — that's what keeps the prompt instant. (Plain repos only; a
# worktree/submodule .git-file just shows no branch, which is fine here.)
function prompt {
  $ok = $?
  $path = $PWD.Path
  if ($path.StartsWith($HOME, [System.StringComparison]::OrdinalIgnoreCase)) {
    $path = '~' + $path.Substring($HOME.Length)
  }

  $branch = ''
  $dir = $PWD.Path
  while ($dir) {
    $head = Join-Path $dir '.git\HEAD'
    if (Test-Path -LiteralPath $head) {
      $ref = (Get-Content -LiteralPath $head -Raw).Trim()
      $branch = if ($ref -like 'ref: refs/heads/*') { $ref.Substring(16) }
                elseif ($ref)                        { $ref.Substring(0, [Math]::Min(7, $ref.Length)) }
                else                                 { '' }
      break
    }
    $parent = Split-Path $dir -Parent
    if ($parent -eq $dir) { break }   # hit the drive root
    $dir = $parent
  }

  $e = [char]27
  $dirPart  = "$e[34m$path$e[0m"                                       # blue path
  $gitPart  = if ($branch) { " $e[36m$branch$e[0m" } else { '' }        # cyan branch
  $markPart = if ($ok)     { "$e[32m>$e[0m" }       else { "$e[31m>$e[0m" }  # green/red >
  "$dirPart$gitPart`n$markPart "
}

# ---- File-listing colors (Get-ChildItem) ----
# Tokyo Night colors, and override PS7's default blue-background dirs (ugly solid bars).
# Pure in-process assignment — no startup cost.
if ($PSStyle) {
  $PSStyle.FileInfo.Directory    = $PSStyle.Bold + $PSStyle.Foreground.FromRgb(0x7aa2f7)  # blue
  $PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.FromRgb(0x7dcfff)                   # cyan
  $PSStyle.FileInfo.Executable   = $PSStyle.Foreground.FromRgb(0x9ece6a)                   # green
}

# ---- Aliases / functions (zero cost, kept for ergonomics) ----
function ll { Get-ChildItem -Force @args }         # long listing incl. hidden (== zsh `ls -lah`)
function la { Get-ChildItem -Force -Name @args }   # names only, incl. hidden (== zsh `ls -A`)
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# ---- zoxide (smarter cd: `z <dir>` frecency jump, `zi` fuzzy pick via fzf) ----
# `zoxide init` spawns the binary, so cache its output to disk and dot-source the cache;
# a new WezTerm pane then pays no subprocess. After upgrading zoxide, delete the cache
# (setup\update.ps1 does this) so the next shell regenerates it from the new binary.
$zoxideCache = Join-Path ([IO.Path]::GetTempPath()) 'zoxide_init.ps1'
if (-not (Test-Path $zoxideCache)) {
  $zoxideExe = (Get-Command zoxide -ErrorAction SilentlyContinue)?.Source
  if ($zoxideExe) {
    # Write to a PID-tagged temp first, then promote — so a failed init or two panes
    # launching at once can't leave a half-written cache that every future shell sources.
    $tmp = "$zoxideCache.$PID.tmp"
    & $zoxideExe init powershell | Out-File -Encoding utf8 $tmp
    if ((Test-Path $tmp) -and (Get-Item $tmp).Length -gt 0) { Move-Item -Force $tmp $zoxideCache }
    else { Remove-Item $tmp -ErrorAction SilentlyContinue }
  }
}
if (Test-Path $zoxideCache) { . $zoxideCache }
