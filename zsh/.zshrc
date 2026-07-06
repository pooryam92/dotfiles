# ~/.zshrc — managed by dotfiles (symlinked by install.sh)

# ---- PATH ----
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"   # matches pwsh/profile.ps1; both installers provide nvim

# ---- History ----
# 50k lines, shared live across shells, written per-command, deduped.
# HIST_IGNORE_SPACE: a leading space keeps a command out of history (secrets).
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY INC_APPEND_HISTORY EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# ---- Options ----
# AUTO_CD: a bare directory name cd's into it (`/tmp` ≡ `cd /tmp`).
setopt AUTO_CD INTERACTIVE_COMMENTS GLOB_DOTS NO_BEEP

# ---- Completion ----
autoload -Uz compinit && compinit -d "$HOME/.cache/zcompdump"
zstyle ':completion:*' menu select                       # Tab opens an arrow-key menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive matching

# ---- Keybindings (emacs) ----
# `bindkey -e` selects emacs-style line editing: every motion/edit key is always on
# with no mode to track — Ctrl+A/E (start/end), Ctrl+W (kill word back), Ctrl+U
# (kill line), Ctrl+R (history). It's zsh's default, but we set it explicitly to
# mirror pwsh's EditMode='Emacs'. For anything long/multi-line, Ctrl+X Ctrl+E drops
# into $EDITOR (below): instant edits here, full nvim when you actually need it.
bindkey -e
bindkey '^[[A' history-search-backward   # Up:   prefix-search history
bindkey '^[[B' history-search-forward    # Down: prefix-search history

# Ctrl+X Ctrl+E: edit the current command line in $EDITOR (nvim); save+quit runs it.
# `^X^E` is the readline/bash convention, mirrored on pwsh as ViEditVisually.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Alt+.: insert the last argument of the previous command (repeat to walk older
# ones) — readline's classic "reuse that path" key. Mirrors pwsh's YankLastArg.
bindkey '^[.' insert-last-word

# Accepting autosuggestions needs no extra bindings in emacs mode: Ctrl+E
# (end-of-line) accepts the whole suggestion and Alt+F (forward-word) the next word
# — both are zsh-autosuggestions' default accept widgets and the same keys on pwsh.
# That's why we DON'T rebind Ctrl+F: it stays emacs forward-char (move right).

# ---- Aliases ----
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# ---- Plugins (apt: zsh-autosuggestions, zsh-syntax-highlighting) ----
# syntax-highlighting must be sourced last
for f in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [ -r "$f" ] && source "$f"
done

# ---- Prompt (native — mirrors the pwsh prompt in pwsh/profile.ps1) ----
# Blue ~-abbreviated path + cyan git branch, then a `>` on its own line that turns
# red after a failed command. The branch is read straight from .git/HEAD instead of
# shelling out to `git` on every prompt draw — zero subprocesses, same trick as the
# pwsh prompt. (Plain repos only; a worktree/submodule .git-file just shows no
# branch, which is fine here.)
_prompt_git_branch() {
  local dir=$PWD ref
  psvar[1]=''
  while :; do
    if [[ -f $dir/.git/HEAD ]]; then
      ref="$(<"$dir/.git/HEAD")"
      case $ref in
        'ref: refs/heads/'*) psvar[1]=${ref#ref: refs/heads/} ;;  # branch name
        ?*)                  psvar[1]=${ref[1,7]} ;;              # detached: short sha
      esac
      return
    fi
    [[ $dir == / || -z $dir ]] && return
    dir=${dir:h}   # step up to the parent directory
  done
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _prompt_git_branch
# %~ = path with ~ abbreviation · %1v = psvar[1] (branch), shown only when set
# (%(1V…)) · %(?…) switches the > color on the last command's exit status.
PROMPT=$'%F{blue}%~%f%(1V. %F{cyan}%1v%f.)\n%(?.%F{green}.%F{red})>%f '

# ---- zoxide (smarter cd) ----
# `z <dir>` jumps to the most "frecent" matching directory; `zi` picks one
# interactively (needs fzf).
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# ---- fzf key-bindings ----
# Ctrl+R fuzzy history · Ctrl+T insert a file path · Alt+C fuzzy-cd. `fzf --zsh`
# emits all three (fzf 0.48+); older apt builds ship them as a script we source
# instead. Same keys on pwsh via hand-rolled handlers in pwsh/profile.ps1.
#
# fd feeds Ctrl+T / Alt+C so they respect .gitignore, skip .git, and run fast;
# bat gives Ctrl+T a syntax-highlighted preview of the highlighted file.
# (rg needs no wiring — it's a command: `rg <pattern>` searches file CONTENTS.)
if command -v fd >/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
fi
command -v bat >/dev/null && \
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
if command -v fzf >/dev/null; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    for f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/key-bindings.zsh; do
      [ -r "$f" ] && source "$f"
    done
  fi
fi

# Multiplexing (panes/tabs/splits) is handled by WezTerm itself via direct Alt
# chords — see wezterm/wezterm.lua. No multiplexer to start.
