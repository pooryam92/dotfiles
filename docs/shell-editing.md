# Shell line editing — the same keys on both shells

How you **edit the command line** — move the cursor, delete words, reuse history,
drop into an editor. This is deliberately identical on zsh (Linux) and PowerShell
(Windows) so the muscle memory carries across machines (goal #3). It's configured
in `zsh/.zshrc` (`bindkey -e`) and `pwsh/profile.ps1` (`EditMode = 'Emacs'`).

## Why emacs mode, not vi mode?

Both shells *can* do vi-style modal editing, and an earlier version of this repo
did. We switched to **emacs-style** editing on purpose:

- **The command line is short.** Modal editing (Esc → `w`/`b`/`dd`) pays off over
  paragraphs, not over a 60-character command. On one line, always-on keys are
  fewer keystrokes.
- **No mode to track.** The #1 vi-mode annoyance is typing into the wrong mode.
  Emacs keys fire from a cold keystroke — `Ctrl+A`, `Ctrl+E`, `Ctrl+W`, `Ctrl+R`
  all just work, no `Esc` first.
- **You still get full modal editing when it helps** — for anything long, hit
  `Ctrl+X Ctrl+E` to open the command in **nvim** (modal editing, full power),
  save and quit to run it. Best of both: instant inline edits, real editor on
  demand.

This is also what most people actually run on the command line — emacs editing is
the default in zsh, bash, and PSReadLine, and the majority (including most vim
users) leave it there for exactly the reasons above.

## Cheatsheet

| Key                    | Action                                        |
| ---------------------- | --------------------------------------------- |
| `Ctrl+A` / `Ctrl+E`    | Jump to **start** / **end** of line           |
| `Alt+B` / `Alt+F`      | Move **back** / **forward** one word          |
| `Ctrl+W`               | Delete the word **behind** the cursor         |
| `Alt+D`                | Delete the word **ahead** of the cursor       |
| `Ctrl+U`               | Kill the **whole line**                        |
| `Ctrl+K`               | Kill from cursor to **end of line**            |
| `Ctrl+Y`               | Paste (yank) what you last killed             |
| `→` / `End` / `Ctrl+E` | Accept the **whole** autosuggestion           |
| `Alt+F`                | Accept the **next word** of the suggestion    |
| `↑` / `↓`              | **Prefix**-search history (type first, then ↑)|
| `Alt+.`                | Insert the **last argument** of the last command (repeat for older) |
| `Ctrl+X Ctrl+E`        | Edit the current command in **`$EDITOR`** (nvim) |
| `Tab`                  | Completion menu (arrow keys to pick)          |

### fzf fuzzy keys

Wired on both shells (zsh via `fzf --zsh`; Windows PSReadLine ships `Ctrl+R`):

| Key       | Action                                    |
| --------- | ----------------------------------------- |
| `Ctrl+R`  | Fuzzy reverse-search history              |
| `Ctrl+T`  | Insert a file/dir path at the cursor *(zsh)* |
| `Alt+C`   | Fuzzy-`cd` into a subdirectory *(zsh)*    |

## Notes / gotchas

- **`Ctrl+F` is "move right one char"**, not accept-word — that's the emacs
  default and we keep it. Use `Alt+F` to accept the next suggestion word (it also
  moves forward a word when there's no suggestion).
- **A leading space keeps a command out of history** on both shells (zsh
  `HIST_IGNORE_SPACE`; a matching `AddToHistoryHandler` in the pwsh profile).
- **`Ctrl+X Ctrl+E` uses `$EDITOR`** (`nvim`, set in both configs). On Windows it
  runs PSReadLine's `ViEditVisually`, which honors `$env:EDITOR`.
- Reload after editing a config: **zsh** `exec zsh` · **pwsh** `. $PROFILE`.

See also: [zsh.md](zsh.md) (Linux shell in full), [windows.md](windows.md) (the
PowerShell profile), and the WezTerm pane/tab keys in [wezterm.md](wezterm.md).
