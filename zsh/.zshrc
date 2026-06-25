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

# ---- Keybindings (vi) ----
# `bindkey -v` makes the main keymap vi-insert; Esc -> normal mode. Mode shows in
# the prompt via starship's vimcmd_symbol. The arrow bindings below run after -v so
# they bind in the (now vi-insert) keymap and keep working in insert mode.
bindkey -v
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
# Accept the autosuggestion without the arrow keys. end-of-line and forward-word
# are zsh-autosuggestions' default accept / partial-accept widgets, so binding keys
# to them is all that's needed: Ctrl+E takes the whole suggestion, Ctrl+F the next
# word. (vi-insert doesn't bind ^E/^F by default.) Mirrors the PSReadLine keys.
bindkey '^E' end-of-line
bindkey '^F' forward-word

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

# ---- zoxide (smarter cd) ----
# `z <dir>` jumps to the most "frecent" matching directory; `zi` picks one
# interactively (needs fzf). Must init after starship so its prompt hook chains.
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# ---- Zellij auto-start (only inside WezTerm, interactive, not nested) ----
if [[ -z "$ZELLIJ" && -n "$WEZTERM_PANE" && $- == *i* ]]; then
  if command -v zellij >/dev/null; then
    export ZELLIJ_AUTO_ATTACH=true
    export ZELLIJ_AUTO_EXIT=true
    eval "$(zellij setup --generate-auto-start zsh)"
  fi
fi
