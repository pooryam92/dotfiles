# ~/.zshrc — managed by dotfiles (symlinked by install.sh)

# ---- PATH ----
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"

# ---- History ----
# A leading space keeps a command out of history.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY INC_APPEND_HISTORY EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# ---- Options ----
setopt AUTO_CD INTERACTIVE_COMMENTS GLOB_DOTS NO_BEEP

# ---- Completion ----
autoload -Uz compinit && compinit -d "$HOME/.cache/zcompdump"
zstyle ':completion:*' menu select                       # Tab opens an arrow-key menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive matching

# ---- Keybindings (emacs) ----
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

bindkey '^[.' insert-last-word

# Ctrl+E accepts the whole autosuggestion and Alt+F the next word, both emacs
# defaults — so Ctrl+F is deliberately left as forward-char.

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

# ---- Prompt (native) ----
# The branch is read straight from .git/HEAD instead of spawning git on every draw.
# Inside a worktree .git is a file holding "gitdir: <path>", which may be relative.
_prompt_git_branch() {
  local dir=$PWD gitdir ref
  psvar[1]=''
  while :; do
    gitdir=''
    if [[ -d $dir/.git ]]; then
      gitdir=$dir/.git                                  # plain repo
    elif [[ -f $dir/.git ]]; then
      gitdir="$(<"$dir/.git")"                          # worktree/submodule
      gitdir=${gitdir#gitdir: }
      [[ $gitdir == /* ]] || gitdir=$dir/$gitdir        # the path may be relative
    fi
    if [[ -n $gitdir && -f $gitdir/HEAD ]]; then
      ref="$(<"$gitdir/HEAD")"
      case $ref in
        'ref: refs/heads/'*) psvar[1]=${ref#ref: refs/heads/} ;;  # branch name
        ?*)                  psvar[1]=${ref[1,7]} ;;              # detached: short sha
      esac
      return
    fi
    [[ $dir == / || -z $dir ]] && return
    dir=${dir:h}
  done
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _prompt_git_branch
# %~ = path with ~ · %1v = branch when set · %(?…) colors > by exit status.
PROMPT=$'%F{blue}%~%f%(1V. %F{cyan}%1v%f.)\n%(?.%F{green}.%F{red})>%f '

# ---- zoxide (smarter cd) ----
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# ---- fzf key-bindings ----
# `fzf --zsh` emits Ctrl+R/Ctrl+T/Alt+C on 0.48+; older apt builds ship a script instead.
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

# Panes and tabs are WezTerm-native; nothing to start here.
