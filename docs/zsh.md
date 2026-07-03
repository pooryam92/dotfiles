# zsh

[zsh](https://www.zsh.org) is the **shell** — the program that reads what you
type, runs commands, and manages history/completion/aliases. It's the glue of
this setup: it loads the plugins and starts Starship. (Panes/tabs are WezTerm's
job now — see [wezterm.md](wezterm.md) — not the shell's.)

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
export EDITOR="nvim"
```

- Puts `~/.local/bin` first on `PATH` — that's where `install.sh` puts Starship,
  Neovim, and zoxide, so user binaries win over system ones.
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
autoload -Uz edit-command-line; zle -N edit-command-line
bindkey '^X^E' edit-command-line
bindkey '^[.' insert-last-word
```

- `bindkey -e` — **emacs-style line editing**: every edit key is always on, with no
  mode to track. `Ctrl+A`/`Ctrl+E` jump to start/end, `Ctrl+W` deletes the word
  behind the cursor, `Ctrl+U` kills the line, `Ctrl+R` searches history. It's zsh's
  default, set explicitly to match PowerShell's `EditMode Emacs` so both shells edit
  the same way. (For long commands, `Ctrl+X Ctrl+E` opens `$EDITOR` — see below.)
- `↑`/`↓` do a **prefix history search**: type `git ` then `↑` to cycle only
  through past commands starting with `git`.
- `Ctrl+X Ctrl+E` — open the current command line in `$EDITOR` (nvim); save and
  quit to run it. The readline/bash convention, for anything too long to edit
  comfortably inline.
- `Alt+.` — insert the **last argument** of the previous command (repeat to walk
  further back) — the classic "reuse that path/filename" key.
- Accepting autosuggestions needs no extra bindings here: `Ctrl+E` (`end-of-line`)
  takes the **whole** suggestion and `Alt+F` (`forward-word`) the **next word** —
  both are zsh-autosuggestions' default accept widgets, and the same keys work on
  Windows (see [windows.md](windows.md)). `Ctrl+F` stays `forward-char` (move right).

### Aliases

```sh
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
```

| Alias    | Expands to             |
| -------- | ---------------------- |
| `ll`     | `ls -lah` (long, all, human sizes) |
| `la`     | `ls -A` (all but `.`/`..`) |
| `..`     | `cd ..`                |
| `...`    | `cd ../..`             |

### Plugins

```sh
for f in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [ -r "$f" ] && source "$f"
done
```

- **autosuggestions** — shows a greyed-out suggestion from history as you type;
  press `→`, `End`, or `Ctrl+E` to accept the whole thing, or `Alt+F` for just
  the next word.
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

### zoxide (smarter cd)

```sh
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
```

Adds the `z` command — `z dot` jumps to the most "frecent" directory matching
`dot`. Initialised after Starship so its prompt hook chains rather than clobbers.
See [zoxide.md](zoxide.md).

### fzf key-bindings

```sh
if command -v fzf >/dev/null; then
  if fzf --zsh >/dev/null 2>&1; then source <(fzf --zsh)
  else for f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/key-bindings.zsh; do
    [ -r "$f" ] && source "$f"; done
  fi
fi
```

Wires three fuzzy keys: **`Ctrl+R`** fuzzy history search, **`Ctrl+T`** insert a
file/dir path at the cursor, **`Alt+C`** fuzzy-cd into a subdirectory. `fzf --zsh`
emits all three on fzf 0.48+; older apt builds ship them as a script, so we fall
back to sourcing that. The same three keys are wired in `pwsh/profile.ps1` via the
PSFzf module, so the muscle memory is identical on both shells.

> **No multiplexer here.** Panes, tabs, and splits are handled by WezTerm itself
> (direct Alt chords — see [wezterm.md](wezterm.md)), so the
> shell doesn't launch Zellij or tmux. Opening a WezTerm window drops you straight
> at the prompt.

---

## Day-to-day usage

- **Accept an autosuggestion:** `→`, `End`, or `Ctrl+E`. Accept one word: `Alt+F`.
- **Search history fuzzily by prefix:** type a few chars, then `↑`/`↓`.
- **Move on the line:** `Ctrl+A`/`Ctrl+E` jump to start/end, `Alt+B`/`Alt+F` by
  word, `Ctrl+W` deletes the word behind the cursor, `Ctrl+U` kills the line.
- **Reuse the last command's last argument:** `Alt+.` (repeat for older ones).
- **Don't record a command:** start it with a leading space.
- **Edit a long command in `$EDITOR`:** `Ctrl+X Ctrl+E`.
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

**Add a tool that needs shell init** (e.g. nvm, direnv) — add its init line near
the Starship line, e.g.:
```sh
command -v direnv >/dev/null && eval "$(direnv hook zsh)"
```
(zoxide and fzf are already wired in this way — see [zoxide.md](zoxide.md).)

---

## Cheatsheet

These are the shell-shared editing keys — identical on PowerShell (see the
cross-shell reference in [shell-editing.md](shell-editing.md)).

| Key            | Action                            |
| -------------- | --------------------------------- |
| `→` / `End` / `Ctrl+E` | Accept whole autosuggestion |
| `Alt+F`        | Accept next word of suggestion    |
| `↑` / `↓`      | Prefix-search history             |
| `Ctrl+A` / `Ctrl+E` | Jump to start / end of line  |
| `Alt+B` / `Alt+F`   | Move backward / forward a word |
| `Ctrl+W`       | Delete word backward              |
| `Ctrl+U`       | Kill the whole line               |
| `Alt+.`        | Insert last arg of previous command |
| `Ctrl+X Ctrl+E`| Edit the command in `$EDITOR` (nvim) |
| `Ctrl+R`       | Fuzzy reverse-search history (fzf)|
| `Ctrl+T`       | Insert a file/dir path (fzf)      |
| `Alt+C`        | Fuzzy-cd into a subdirectory (fzf)|
| `Tab`          | Completion menu (arrow to pick)   |
