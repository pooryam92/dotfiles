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

# ---- cheat: learn-the-terminal sheet (one implementation, in cheat.py) ----
# The logic lives ONCE in ~/.config/cheat.py (a Python + Textual app; the pwsh
# wrapper shares it, so there's no second port to keep in sync). install.sh builds
# a small venv at ~/.local/share/cheat/venv with Textual for the TUI; we prefer
# that interpreter and fall back to the system python3 (plain-text mode) without
# it. Bare `cheat` opens the TUI / menu; `cheat <category|word|all>` prints once.
cheat() {
  local py="$HOME/.local/share/cheat/venv/bin/python"
  [ -x "$py" ] || py="$(command -v python3)"
  [ -n "$py" ] || { print -u2 "cheat: needs python3"; return 1; }
  "$py" "$HOME/.config/cheat.py" "$@"
}
# Once-a-day nudge: show one random tip the first time you open a shell each day,
# so the keys teach themselves without you having to remember the tool exists. The
# date check is done here (cheap) so python only spawns on a genuinely new day, not
# on every shell — keeps startup fast. Stamp lives in the cache dir, not the repo.
() {
  local stamp="${XDG_CACHE_HOME:-$HOME/.cache}/cheat/last-tip"
  local today=$(date +%Y%m%d)
  [ "$(cat "$stamp" 2>/dev/null)" = "$today" ] && return
  mkdir -p "${stamp:h}" && print -r -- "$today" > "$stamp"
  cheat tip
}

# ---- keymap: your personal shell-usage heatmap (+ data for an agent) -------
# Reads this shell's history and shows what you actually lean on — top commands,
# busy subcommands, and aliases you defined but never use.
# Same Python+Textual venv as `cheat` (shared, not a second dependency); falls
# back to a plain printed report without it. Bare `keymap` opens the TUI;
# `keymap --plain` prints once; `keymap --json` feeds the `/keymap` agent.
keymap() {
  local py="$HOME/.local/share/cheat/venv/bin/python"
  [ -x "$py" ] || py="$(command -v python3)"
  [ -n "$py" ] || { print -u2 "keymap: needs python3"; return 1; }
  "$py" "$HOME/.config/keymap.py" "$@"
}
