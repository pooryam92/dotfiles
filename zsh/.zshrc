# ~/.zshrc — managed by dotfiles (symlinked by install.sh)

# ---- PATH ----
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="vi"

# ---- History ----
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY INC_APPEND_HISTORY EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# ---- Options ----
setopt AUTO_CD INTERACTIVE_COMMENTS GLOB_DOTS NO_BEEP

# ---- Completion ----
autoload -Uz compinit && compinit -d "$HOME/.cache/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ---- Keybindings (emacs) ----
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ---- Aliases ----
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias zj='zellij'

# ---- Plugins (apt: zsh-autosuggestions, zsh-syntax-highlighting) ----
# syntax-highlighting must be sourced last
for f in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [ -r "$f" ] && source "$f"
done

# ---- Starship prompt ----
command -v starship >/dev/null && eval "$(starship init zsh)"

# ---- Zellij auto-start (only inside WezTerm, interactive, not nested) ----
if [[ -z "$ZELLIJ" && -n "$WEZTERM_PANE" && $- == *i* ]]; then
  if command -v zellij >/dev/null; then
    export ZELLIJ_AUTO_ATTACH=true
    export ZELLIJ_AUTO_EXIT=true
    eval "$(zellij setup --generate-auto-start zsh)"
  fi
fi
