# keymap

`keymap` is your **personal shell-usage heatmap** — and the data feed for an agent
that improves this repo. It reads your shell history and shows what you *actually*
lean on: your most-run commands, which subcommands dominate, and the aliases you
defined but never use. Then `/keymap` (a Claude Code command) reads the same data
and proposes concrete dotfiles tweaks.

```sh
keymap                # interactive TUI (vim keys) — flip between views
keymap --plain        # print the whole report once (good for piping / scrollback)
keymap --json         # structured, secret-redacted profile (what /keymap reads)
keymap --days 30      # only the last 30 days
keymap version        # print the version
```

It's the **second tool in the suite** after [`cheat`](cheat.md), built on the same
template: a small Python package, a shared Textual venv, graceful degradation. It
also shares `cheat`'s `tools/tui/` browser, so the two TUIs feel identical. The
split that makes it interesting is **sense vs. agent**:

- **Sense layer** — the `tools/keymap/` package only *measures* (history → redact →
  parse → profile, behind a thin `keymap.py` entry). No opinions, no
  hardcoded "if you do X, do Y" rules to rot. Just facts about your usage.
- **Agent layer** — the `/keymap` slash command reads those facts plus the current
  repo, *reasons* about what's worth changing, and proposes diffs you approve. The
  intelligence lives in the model, fresh each run — not baked into the tool.

---

## The views (bare `keymap`)

In a real terminal (with Textual installed) `keymap` opens a two-pane TUI sharing
`cheat`'s lazygit/k9s-style chrome — rounded titled boxes, the focused pane's border
lit in the accent, the chart box's border naming the current view, and a bottom
keybar. A list of views sits on the left, the chart on the right. It's
**vim-navigable** — the same hjkl muscle memory as `cheat`, your shell, Neovim, and
Zed.

| View            | What it shows                                                  |
| --------------- | -------------------------------------------------------------- |
| Overview        | totals, date span, favourites, unused aliases                  |
| Top commands    | your most-run programs as ranked ASCII bars                    |
| Subcommands     | drill into busy tools — which `git`/`docker`/… subcommands dominate |
| Aliases         | used vs. **missed** (times you typed the long form anyway), plus alias candidates |

| Key            | Action                                              |
| -------------- | --------------------------------------------------- |
| `j` / `k`      | move down / up the view list                        |
| `g` / `G`      | jump to the first / last view                       |
| `l` or `Enter` | enter the chart pane (to scroll a long one)         |
| `j` / `k`      | *(in the pane)* scroll line by line                 |
| `h` or `Esc`   | back to the view list                               |
| `q`            | quit                                                |

---

## The agent: `/keymap`

Run `/keymap` inside Claude Code (optionally `/keymap --days 30`). It:

1. Runs `keymap --json` to get your secret-redacted usage profile.
2. Reads the current setup — aliases, keybindings, `cheat.tsv`, the repo goals.
3. Proposes a **prioritized** list of changes, each with the *evidence* (a real
   number from your history), the *diff*, and the *why* (which goal it serves).
4. Applies them **after you approve** — keeping cross-platform parity (both shells)
   and adding a `cheat.tsv` entry so any new shortcut is discoverable.

Example nudges it might surface: *"you typed `cd ..` 4× but `..` already exists"*,
*"`gco` is defined but never used"*, *"you `cd` into the same three dirs constantly —
lean on `z`"*, *"this 40-char command ran 6× — worth an alias?"*.

---

## Privacy — redaction happens first

Shell history can contain secrets (a token on a `curl`, a `--password=` flag). Every
command line is run through a **redactor before it is counted, shown, or emitted** —
passwords, API keys, bearer tokens, provider-prefixed keys (`ghp_…`, `sk-…`), JWTs,
URLs with `user:pass@`, and long high-entropy blobs all become `‹redacted›`. So the
report and the JSON the agent reads never carry raw secrets.

It's not a guarantee against every exotic secret shape, but it covers the common
ones — and the data never leaves your machine (the agent is your local Claude).

---

## How it's wired in this repo

`keymap` follows the [`cheat`](cheat.md) template, so the moving parts are the same:

**Runtime** — a Python + Textual TUI. Textual lives in the **shared venv** at
`~/.local/share/cheat/venv` (built by the installer for `cheat`); `keymap` reuses it,
so there's no second dependency to install or update.

**Installers** (`install.sh` / `install.ps1`) — symlink `keymap.py` into `~/.config`
and the `/keymap` command into `~/.claude/commands`. No new venv step.

**Shell wrappers** (`zsh/.zshrc`, `pwsh/profile.ps1`) — thin launchers that prefer
the venv's interpreter and fall back to the system Python:

```sh
keymap() {
  local py="$HOME/.local/share/cheat/venv/bin/python"
  [ -x "$py" ] || py="$(command -v python3)"
  [ -n "$py" ] || { print -u2 "keymap: needs python3"; return 1; }
  "$py" "$HOME/.config/keymap.py" "$@"
}
```

**Updates** (`update.sh` / `update.ps1`) — nothing keymap-specific: keeping the
shared venv's Textual current (already done for `cheat`) covers it.

### Graceful degradation

Like `cheat`, it works in tiers so it's useful before Textual is installed and pipes
cleanly:

| Situation                                  | What you get                          |
| ------------------------------------------ | ------------------------------------- |
| Terminal **with** Textual                  | the full vim-navigable TUI            |
| Terminal **without** Textual               | the plain printed report              |
| Output piped / redirected, or `--plain`    | plain text (ANSI only on a TTY)       |
| `--json`                                   | the structured profile (no TUI ever)  |

---

## The data model

There's no data file to maintain — the "data" is **your history**, read live:

| OS            | History source                                                        | Timestamps? |
| ------------- | --------------------------------------------------------------------- | ----------- |
| Linux / zsh   | `~/.zsh_history` (or `$HISTFILE`)                                      | yes (`EXTENDED_HISTORY`) → `--days` & date span |
| Windows / pwsh| PSReadLine's `ConsoleHost_history.txt`                                | no → `--days` is a no-op, span is blank |

Override the source with `$KEYMAP_HISTFILE` (handy for testing on a fixture).

The zsh **`EXTENDED_HISTORY`** setting (already on in `zsh/.zshrc`) records a
timestamp per command — that's what lets `--days N` window the history and the
report show a date span. PSReadLine doesn't timestamp, so those degrade gracefully
(the counts still work).

---

## Design notes — the *why*

- **Why split sense from agent?** The first sketch had hardcoded nudges ("`cd` >20× →
  zoxide"). That rots: thresholds are arbitrary and the rules never fit *your*
  situation. Letting the model reason over raw data each time is both simpler (no
  rules table) and smarter (it sees the whole picture, including the repo).
- **Why reuse cheat's venv?** Goal #2 — stay simple. A second Textual install would
  be ~50 MB of duplication for no benefit; one shared venv serves both TUIs.
- **Why redact in the tool, not the agent?** Defense in depth: the secret never even
  reaches the agent's context, so there's nothing to leak in a transcript.
- **Why measure, not just guess?** Goal #1 is a faster terminal. You can't speed up
  what you can't see — `keymap` turns a vague "I type too much" into "you typed this
  exact thing 17 times," which is what makes a fix obvious.

---

## Roadmap

Natural next steps, all agent-side (the sense layer stays small): a scheduled weekly
"terminal tune-up" that surfaces suggestions via `/loop` or a routine; richer Windows
support if PSReadLine ever grows timestamps; and feeding the same profile into other
commands (e.g. auto-proposing `cheat.tsv` entries for tools you use but haven't
learned the shortcuts for).
