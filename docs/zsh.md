# zsh

[zsh](https://www.zsh.org) is the **shell** — the program that reads what you
type, runs commands, and manages history/completion/aliases. It's the glue of
this setup: it loads the plugins, starts Starship, and auto-launches Zellij.

This config is **plugin-manager-free** — it uses the two plugins packaged by
apt and sources them directly, so there's nothing extra to update.

- Docs: <https://zsh.sourceforge.io/Doc/>
- A gentler guide: <https://thevaluable.dev/zsh-install-configure-mouseless/>
- Your config: `zsh/.zshrc` → symlinked to `~/.zshrc`

`~/.zshrc` runs once per **interactive** shell. Edit it, then `exec zsh` (or open
a new shell) to apply.

---

## Your config, explained

### PATH and editor

```sh
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="vi"
```

- Puts `~/.local/bin` first on `PATH` — that's where `install.sh` puts Zellij and
  Starship, so user binaries win over system ones.
- `EDITOR` is what tools open when they need you to edit something (git commit
  messages, `fc`, etc.).

### History

```sh
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY INC_APPEND_HISTORY EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
```

- `HISTSIZE` / `SAVEHIST` — keep 50k lines in memory and on disk.
- `SHARE_HISTORY` — history is shared **live** across all open shells.
- `INC_APPEND_HISTORY` — write each command as you run it (not just on exit).
- `EXTENDED_HISTORY` — also store timestamps.
- `HIST_IGNORE_ALL_DUPS` — drop older duplicates so history stays clean.
- `HIST_IGNORE_SPACE` — a command typed with a **leading space** isn't recorded
  (handy for secrets).
- `HIST_REDUCE_BLANKS` — tidy up extra whitespace before saving.

### Options

```sh
setopt AUTO_CD INTERACTIVE_COMMENTS GLOB_DOTS NO_BEEP
```

- `AUTO_CD` — type a directory name with no `cd` to enter it (`/tmp` ≡ `cd /tmp`).
- `INTERACTIVE_COMMENTS` — allow `#` comments on the command line.
- `GLOB_DOTS` — let `*` match dotfiles too.
- `NO_BEEP` — silence the terminal bell.

### Completion

```sh
autoload -Uz compinit && compinit -d "$HOME/.cache/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
```

- `compinit` — turns on zsh's powerful tab-completion system (caches its dump in
  `~/.cache`).
- `menu select` — `Tab` shows an interactive menu you can arrow through.
- `matcher-list` — **case-insensitive** completion (`cd dow<Tab>` finds
  `Downloads`).

### Keybindings

```sh
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
```

- `bindkey -e` — emacs-style line editing (`Ctrl+a` start of line, `Ctrl+e` end,
  `Ctrl+w` delete word, etc.).
- `↑`/`↓` do a **prefix history search**: type `git ` then `↑` to cycle only
  through past commands starting with `git`.

### Aliases

```sh
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias zj='zellij'
```

| Alias    | Expands to             |
| -------- | ---------------------- |
| `ll`     | `ls -lah` (long, all, human sizes) |
| `la`     | `ls -A` (all but `.`/`..`) |
| `..`     | `cd ..`                |
| `...`    | `cd ../..`             |
| `zj`     | `zellij`               |

### Plugins

```sh
for f in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [ -r "$f" ] && source "$f"
done
```

- **autosuggestions** — shows a greyed-out suggestion from history as you type;
  press `→` (or `End`) to accept it.
- **syntax-highlighting** — colors your command line as you type (valid commands
  green, unknown red, quotes/paths highlighted). **Must be sourced last**, which
  is why it's the second entry.
- The `[ -r "$f" ]` guard means it silently skips if a plugin isn't installed.

### Starship prompt

```sh
command -v starship >/dev/null && eval "$(starship init zsh)"
```

Hands prompt rendering over to Starship if it's installed. See
[starship.md](starship.md).

### Zellij auto-start

```sh
if [[ -z "$ZELLIJ" && -n "$WEZTERM_PANE" && $- == *i* ]]; then
  if command -v zellij >/dev/null; then
    export ZELLIJ_AUTO_ATTACH=true
    export ZELLIJ_AUTO_EXIT=true
    eval "$(zellij setup --generate-auto-start zsh)"
  fi
fi
```

Auto-starts Zellij **only** when all three are true:
- `-z "$ZELLIJ"` — we're not already inside a Zellij session (no nesting).
- `-n "$WEZTERM_PANE"` — we're running inside WezTerm (this var is set by
  WezTerm). So SSH, other terminals, and IDE shells stay plain.
- `$- == *i*` — this is an interactive shell.

Then:
- `ZELLIJ_AUTO_ATTACH=true` — reattach an existing session instead of making a
  new one.
- `ZELLIJ_AUTO_EXIT=true` — when you exit Zellij, exit the shell too (so the
  WezTerm window closes instead of dropping to a bare prompt).

> On Windows the same guard lives in `pwsh/profile.ps1` (keyed on
> `$env:WEZTERM_PANE`); see [windows.md](windows.md).

---

## Day-to-day usage

- **Accept an autosuggestion:** `→` or `End`. Accept one word: `Alt+f`.
- **Search history fuzzily by prefix:** type a few chars, then `↑`/`↓`.
- **Jump on the line:** `Ctrl+a` (start), `Ctrl+e` (end), `Ctrl+w` (delete word
  back), `Ctrl+u` (delete to start), `Ctrl+k` (delete to end).
- **Don't record a command:** start it with a leading space.
- **Edit a long command in `$EDITOR`:** `Ctrl+x Ctrl+e`.
- **Reload config after editing:** `exec zsh`.

---

## Common tweaks

**Add an alias or env var** — anywhere in the Aliases section:
```sh
alias gs='git status'
alias gp='git pull'
export EDITOR="nvim"
```

**Add a function** (for things aliases can't do):
```sh
mkcd() { mkdir -p "$1" && cd "$1"; }
```

**Disable Zellij auto-start** — delete the last `if` block in `zsh/.zshrc`.

**Add a tool that needs shell init** (e.g. zoxide, fzf, nvm) — add its init
line near the Starship line, e.g.:
```sh
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
```

---

## Cheatsheet

| Key            | Action                          |
| -------------- | ------------------------------- |
| `→` / `End`    | Accept autosuggestion           |
| `↑` / `↓`      | Prefix-search history           |
| `Ctrl+a/e`     | Start / end of line             |
| `Ctrl+w`       | Delete word backward            |
| `Ctrl+u/k`     | Delete to start / end of line   |
| `Ctrl+r`       | Reverse-search history          |
| `Ctrl+x Ctrl+e`| Edit command in `$EDITOR`       |
| `Tab`          | Completion menu (arrow to pick) |
