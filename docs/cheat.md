# cheat

`cheat` is a **learn-the-terminal cheat sheet** that lives in your shell. Instead
of a static page you scroll, it's a small interactive tool that teaches the keys
and commands in *this* setup — grouped by category, in the order worth learning
them, each key paired with a short *why*.

```sh
cheat                # interactive TUI (vim keys)
cheat basics         # jump straight to one lesson
cheat pane           # search every entry for "pane"
cheat all            # print every lesson (good for piping / grep)
cheat tip            # print one random tip (the once-a-day shell nudge)
cheat version        # print the version
```

Your shell shows one random `cheat tip` the **first time you open a terminal each
day** — so the keys teach themselves without you having to remember the tool is
there. See [The daily nudge](#the-daily-nudge) below.

- Implemented **once** in the `tools/cheat/` package (Python + [Textual](https://textual.textualize.io)).
- Both shells just launch it — no second port to keep in sync.
- Data lives beside it in two small TSV files; adding a key or a whole category is a one-line edit.

---

## The three views

### 1. The TUI — bare `cheat`

In a real terminal (with Textual installed) `cheat` opens a two-pane TUI: the
category list on the left, the lesson on the right. It updates live as you move,
and it's **vim-navigable** — the same hjkl muscle memory as your shell, Neovim,
and Zed. Press `/` to filter across every entry; matches are highlighted and
counted as you type.

| Key            | Action                                              |
| -------------- | --------------------------------------------------- |
| `j` / `k`      | move down / up the category list                    |
| `g` / `G`      | jump to the first / last category                   |
| `l` or `Enter` | enter the lesson pane (to scroll a long lesson)     |
| `j` / `k`      | *(in the lesson)* scroll line by line               |
| `g` / `G`      | *(in the lesson)* top / bottom                      |
| `h` or `Esc`   | *(in the lesson)* back to the category list         |
| `/`            | search across every entry                           |
| `Esc`          | close the search box                                |
| `q`            | quit                                                |

### 2. Lessons — `cheat <category>`

Prints one category's keys with their tips and exits. Category names are the ones
in the left pane (`basics`, `wezterm`, `mode`, `shell`, `fuzzy`, `nav`):

```sh
cheat basics
cheat all          # every category at once
```

### 3. Search — `cheat <word>`

Any argument that isn't a category name is treated as a search across category,
key, action and tip:

```sh
cheat copy         # everything mentioning "copy"
cheat ctrl+r       # find a specific key
```

Both lessons and search **print once** (no TUI), so they pipe and grep cleanly:

```sh
cheat all | grep -i split
```

---

## The daily nudge

A cheat sheet you have to remember to open rarely gets opened — and the moment
you'd benefit from a shortcut is exactly when you're heads-down and won't break
flow to read a TUI. So the knowledge comes to *you*: the **first shell you open
each day** prints one random tip.

```
  tip  Ctrl+r  fuzzy-search command history
       → type a few letters of an old command, Enter to run it
       more: cheat fuzzy
```

The `more:` line points at the matching lesson, so a tip is one keystroke from the
rest of its category.

It's throttled to **once a day, total** — opening five terminals shows it once,
not five times. The date check lives in the shell wrappers (`zsh/.zshrc`,
`pwsh/profile.ps1`), not in Python, on purpose: comparing a date string is
free, so `python` only spawns on a genuinely new day rather than on every shell —
keeping startup fast (goal #1). The "last shown" stamp lives in the cache dir
(`$XDG_CACHE_HOME/cheat/last-tip`, or `%LOCALAPPDATA%\cheat\last-tip` on Windows),
never in the repo. Run `cheat tip` yourself anytime for a fresh one.

## How it's wired in this repo

`cheat` is a Python + Textual app, split into the `tools/cheat/` package —
`data.py` (load the TSVs), `content.py` (build the screens as neutral docs),
`cli.py` (args + plain output + launch), behind a thin `cheat.py` entry. The
two-pane browser, vim keys and palette are **not** here: they live in the shared
`tools/tui/` package, which `keymap` reuses too — see that package's docstrings
(`tui/__init__.py`, `doc.py`, `render.py`, `browse.py`) for the seam.

The challenge it solves cross-platform is *the runtime*: Textual is a dependency,
and Pop!_OS ships a [PEP 668](https://peps.python.org/pep-0668/) "externally
managed" Python where `pip install --user` is blocked. So Textual lives in a
**dedicated venv**, and the tool degrades gracefully when it's absent.

**Installers** (`install.sh` / `install.ps1`)

- Install Python (`apt` on Linux — already present; `scoop install python` on Windows).
- Build a venv at `~/.local/share/cheat/venv` and `pip install textual` into it
  (idempotent — skipped if Textual is already there).
- Symlink the entry plus its two data files into `~/.config`: `cheat.py`,
  `cheat.tsv`, `cheat-index.tsv`. The entry resolves its own symlink back into the
  repo to import the `cheat` and `tui` packages (and to find the data), so those
  packages need no links of their own.

**Shell wrappers** (`zsh/.zshrc`, `pwsh/profile.ps1`) — thin launchers that prefer
the venv's interpreter and fall back to the system Python:

```sh
cheat() {
  local py="$HOME/.local/share/cheat/venv/bin/python"
  [ -x "$py" ] || py="$(command -v python3)"
  [ -n "$py" ] || { print -u2 "cheat: needs python3"; return 1; }
  "$py" "$HOME/.config/cheat.py" "$@"
}
```

**Updates** (`update.sh` / `update.ps1`) — keep the venv's Textual current with
`pip install --upgrade textual`.

### Theming

The TUI sets Textual's built-in **`tokyo-night`** theme, which carries the *same*
hexes WezTerm's scheme uses (`#1a1b26` background, `#7aa2f7` blue, `#bb9af7`
purple, `#24283b` surface…) — so the chrome (header, footer, scrollbars,
selection, focus borders) matches the rest of the setup natively. The lesson text
reuses the palette deliberately: **keys in cyan** (Starship's path color),
**category headers in blue** (its language color), **tips in comment-grey**, and
**search matches in yellow**. Colors in the stylesheet are theme *variables*
(`$secondary`, `$panel`, `$boost`…), not hardcoded, so re-theming is one line.

### Graceful degradation

The tool works in three tiers, so it's useful even before Textual is installed
and behaves well in pipes:

| Situation                                  | What you get                          |
| ------------------------------------------ | ------------------------------------- |
| Terminal **with** Textual                  | the full vim-navigable TUI            |
| Terminal **without** Textual               | a plain numbered menu (type a number / `/word` / `q`) |
| Arguments, or output piped / redirected    | plain one-shot text (ANSI only on a TTY) |

---

## The data model

Two tab-separated files (no quoting, no escaping — just tabs):

**`cheat-index.tsv`** — the categories, **in learning order** (row order *is* the order shown):

```
category<TAB>blurb
```

```
Basics	the ~10 keys you'll use every day
WezTerm	panes, tabs, splits — your window manager
```

**`cheat.tsv`** — the entries:

```
category<TAB>key<TAB>action<TAB>tip
```

```
Basics	Ctrl+r	fuzzy-search command history	type a few letters of an old command, Enter to run it
```

The `tip` is the *why* — the one-line teaching note shown under each key.

### Adding to it

- **A new key in an existing category:** append one line to `cheat.tsv`.
- **A new category:** add a line to `cheat-index.tsv` (its position sets where it
  appears in the learning order) and one or more entry lines to `cheat.tsv`.

Because the files are **symlinked** from this repo into `~/.config`, edits are
live immediately — no reinstall, no rebuild. Keep them tab-separated and avoid
double-quotes (a habit from an earlier CSV-based version, and just cleaner).

---

## Design notes — the *why*

- **Why Python?** Fast edit-and-run with no build step or toolchain to install on
  each machine (the cost that ruled out Go/Rust for a small personal tool). The
  trade-off — a runtime on each machine — is cheap here: Linux already has
  `python3`, Windows is one `scoop` package.
- **Why a venv, not `pip --user` or pipx?** PEP 668 blocks `pip --user` on
  Pop!_OS; pipx installs *applications*, not importable libraries. A dedicated
  venv is the simple, robust path that works identically on both OSes.
- **Why Textual (a dependency at all)?** A real cross-platform TUI needs one —
  Python's stdlib `curses` is Unix-only and absent on Windows. Textual fills that
  gap and gives the keyboard-first navigation for free.
- **Why a plain fallback?** So `cheat` is useful the moment the files are linked,
  before Textual finishes installing, and so it pipes/greps like any other CLI.

---

## Roadmap

`cheat` is the **first tool in a small cross-platform suite**; the venv +
graceful-degradation + shared-data pattern here is the template for the next one.
Natural next steps: more categories (git, tmux-style workflows), a `--no-tui`
flag to force plain output, and packaging as a proper `pipx`-installable app once
the suite grows.
