# Claude Code

[Claude Code](https://docs.claude.com/en/docs/claude-code) is Anthropic's
terminal coding agent. This repo version-controls its `settings.json` and adds a
custom **status line** — the single line shown under the prompt while Claude is
working.

```
4.8    dotfiles    main *   ctx 84k/200k   5h 24%   wk 81%
└ model └ dir       └ git    └ context       └ 5-hour └ 7-day plan usage
                              tokens / window
```

The model shows just the version number to save room (`Opus 4.8` → `4.8`); the
family is dropped since it's almost always Opus. Falls back to the full name if
there's no parseable version.

The last two segments (`5h`/`wk`) are your subscription limits — they only show
for Claude.ai Pro/Max accounts, and only after the first API response in a
session.

- Docs: <https://docs.claude.com/en/docs/claude-code/statusline>
- Linked into place by both installers (see the table below).

---

## How it's wired in this repo

Two files are symlinked into `~/.claude/`:

| Repo file              | Target                      | What it is                                  |
| ---------------------- | --------------------------- | ------------------------------------------- |
| `claude/statusline.js` | `~/.claude/statusline.js`   | the status line itself — all the logic      |
| `claude/settings.json` | `~/.claude/settings.json`   | your Claude settings; points at the script  |

The only status-line-specific thing in `settings.json` is a one-line pointer:

```json
"statusLine": { "type": "command", "command": "node ~/.claude/statusline.js" }
```

That command is identical on both machines — Claude Code expands `~` and accepts
forward slashes on Windows and Linux alike, and `statusline.js` lives at the same
`~/.claude/` path on both. So there's no per-machine config to generate.

**Why link the whole `settings.json`?** Because it's a symlink, settings you
change in-app with `/config` write *through* it into this repo — so your Claude
settings are version-controlled and synced across machines, just like every other
config here. (Claude Code is the source of truth, so commit the changes it makes.)

---

## Input line editing

The prompt where you type to Claude has its own editor mode, set by `editorMode`
in `settings.json`. We keep it on **`normal`** (readline/emacs-style, always-on
keys) rather than `vim` — same reasoning as the shell in
[shell-editing.md](shell-editing.md#why-emacs-mode-not-vi-mode): the input is
short, and no-mode-to-track beats modal editing over a line or two. Toggle live
in-session with the `/vim` command; that write persists back into `settings.json`.

The keys are the same emacs bindings as the shell — the ones you'll reach for most:

| Key                 | Action                                   |
| ------------------- | ---------------------------------------- |
| `Ctrl+U`            | Delete from cursor to **start** of line  |
| `Ctrl+K`            | Delete from cursor to **end** of line    |
| `Ctrl+A` / `Ctrl+E` | Jump to **start** / **end** of line      |
| `Ctrl+W`            | Delete the word **behind** the cursor    |

To **delete a whole line**: `Ctrl+A` then `Ctrl+K` (or just `Ctrl+U` when the
cursor is already at the end). See [shell-editing.md](shell-editing.md) for the
full cheatsheet — it carries over here.

---

## How the status line works

Claude Code runs the command after each turn and pipes it a JSON blob on **stdin**
— model, workspace dirs, git, cost, context-window usage, and more. Whatever the
script prints to **stdout** becomes the bar. `statusline.js` reads that JSON and
prints: model, directory, git branch (+ dirty `*`), context-window tokens used
(out of the window size when Claude reports it), and — for Pro/Max accounts —
the 5-hour and 7-day plan-usage percentages from `rate_limits`.

The two usage segments color by percent (a hard quota: green → yellow at 50% →
red at 80%), whereas `ctx` colors by absolute tokens — the 1M window is flat-
priced, so what matters there is attention as it fills, not a cap.

**Why Node?** It's the one runtime guaranteed on both machines — Claude Code runs
on it — so a single script serves every OS with no shell fork (goal #3).

**Why ANSI _named_ colors, not Tokyo Night hex?** Same reason `starship.toml`
says `bold cyan` instead of `#7aa2f7`: named colors resolve against the terminal's
own palette, which WezTerm sets to Tokyo Night. Re-theme the terminal and the bar
follows automatically — no color values to keep in sync. The glyphs and colors
mirror Starship so the bar reads as an extension of the shell prompt.

---

## Customizing

Edit `claude/statusline.js` — it's ~120 commented lines. Each segment is built in
`render()` and pushed onto a list that's joined with two spaces. To add, remove,
or recolor a segment, edit that function. The `paint(code, s)` helper wraps text
in an SGR color (`31` red … `36` cyan, prefix `1;` for bold). The full list of
fields Claude Code sends is in the
[status line docs](https://docs.claude.com/en/docs/claude-code/statusline).

Changes are picked up the next time the bar refreshes (after a turn). Test a
change without waiting by feeding it sample input:

```sh
echo '{"model":{"display_name":"Opus 4.8"},"workspace":{"current_dir":"."}}' \
  | node ~/.claude/statusline.js
```

**Want more than this does?** [ccstatusline](https://github.com/sirmalloc/ccstatusline)
is a powerful TUI-configured alternative (powerline separators, context bars, PR
status, token speeds). Adopting it is a one-line swap — change the `command` to
`npx -y ccstatusline@latest`. We chose a small owned script instead to stay in
line with goal #2 (prefer small, well-commented config over plugins) and to keep
the theme palette-following rather than hardcoded.
