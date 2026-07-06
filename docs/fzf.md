# fzf + fd + rg + bat — fuzzy finding everywhere

Four tools that work as one system. **fzf** is the interactive fuzzy *picker*:
feed it any list, type a few scattered letters (`docwin` → `docs/windows.md`),
arrow to the match, Enter. **fd** produces good file lists for it (fast, skips
`.git/` and everything in `.gitignore`). **bat** renders the syntax-highlighted
preview pane. **rg** (ripgrep) is the odd one out — not a picker, a *command*:
it searches file **contents**.

All four are installed by both installers (apt on Linux — the binaries are
symlinked from Ubuntu's renamed `fdfind`/`batcat` to the real `fd`/`bat` names —
and scoop on Windows).

## The keys (same on zsh and PowerShell)

| Key | What it does | Where it's wired |
| --- | --- | --- |
| `Ctrl+R` | fuzzy-search shell **history** — two remembered words find that three-week-old command | fzf's zsh widget; PSReadLine's built-in reverse-search on pwsh |
| `Ctrl+T` | fuzzy-pick a **file**, insert its path at the cursor — type `nvim `, `Ctrl+T`, fragment, Enter | `zsh/.zshrc` (fzf + `FZF_CTRL_T_COMMAND`) / `pwsh/profile.ps1` (hand-rolled handler) |
| `Alt+C` | fuzzy-pick a **directory** and `cd` into it | same two files |

`Ctrl+T` shows a **preview pane**: the highlighted file's contents, syntax
highlighted by bat, so you can confirm it's the right file before Enter.

The pwsh handlers are deliberately hand-rolled instead of using the PSFzf
module: they invoke fzf only when the key is pressed, so profile startup stays
instant (importing PSFzf cost real milliseconds on every new pane — the reason
it was removed).

## rg — search inside files

```sh
rg keep_sudo_fresh          # where is this used?
rg -i 'tokyo ?night'        # case-insensitive, regex
rg --type lua 'config\.'    # only in .lua files
rg -l TODO                  # just the file names
```

Like fd, it skips `.gitignore`d files and `.git/` by default, which is why it
feels instant even in big repos.

## How they chain

- `zi` (zoxide's interactive mode) uses **fzf** to pick from your frecent dirs.
- `Ctrl+T` runs **fd**, pipes into **fzf**, previews with **bat**.
- `fd`/`rg` honour the same ignore rules, so "files I care about" is consistent
  across finding names (fd), finding content (rg), and picking (fzf).

## Handy standalone uses

```sh
fd wezterm                  # find files by name fragment
fd -e md                    # all markdown files
bat setup/lib.sh            # read a file with highlighting + line numbers
git diff | bat -l diff      # highlight anything piped in
```
