# ~/.zshrc — managed by dotfiles (symlinked by install.sh)

# ---- PATH ----
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"   # matches pwsh/profile.ps1; both installers provide nvim

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

# ---- fzf key-bindings ----
# Ctrl+R fuzzy history · Ctrl+T insert a file path · Alt+C fuzzy-cd. `fzf --zsh`
# emits all three (fzf 0.48+); older apt builds ship them as a script we source
# instead. Mirrors the PSFzf keys in pwsh/profile.ps1 (same keys on both shells).
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
# chords + Ctrl+p/t/n/s modes — see wezterm/wezterm.lua. No multiplexer to start.

# ---- Drills (spaced-repetition learning of this repo's own tools) ----
# `learn` runs a drill session; at shell start, if any cards are due, print one line
# pointing at it (silent otherwise). drill.js lives in the repo and is run in place
# (no symlink): resolve the repo root from THIS file's real path — it's symlinked
# from the repo to ~/.zshrc, so `${(%):-%x}:A` is the repo's zsh/.zshrc and `:h:h`
# is the repo root. Everything is guarded on node so a missing runtime is silent.
if command -v node >/dev/null; then
  _drill_js="${${(%):-%x}:A:h:h}/drills/drill.js"
  if [ -f "$_drill_js" ]; then
    alias learn="node ${(q)_drill_js}"
    _due=$(node "$_drill_js" --count 2>/dev/null)
    if [ "${_due:-0}" -gt 0 ] 2>/dev/null; then
      _word=drills; [ "$_due" -eq 1 ] && _word=drill
      print -P "🎴 $_due $_word due — run %B%F{yellow}learn%f%b"
      unset _word
    fi
    unset _due
  fi
  unset _drill_js
fi
