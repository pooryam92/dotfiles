---
description: Analyze my real shell usage (via the keymap tool) and propose concrete dotfiles improvements
argument-hint: "[--days N]  (optional: only look at the last N days)"
---

You are the **agent layer** of `keymap`. The Python tool (`tools/keymap/keymap.py`)
is the *sense layer* — it measures how the user actually uses their shell. Your job
is to turn that measurement into concrete, approved improvements to **this dotfiles
repo**. The intelligence is you, not a hardcoded rules table — reason fresh from the
data each time.

## 1. Gather the data

Run the tool against real history and read the structured profile (it is already
**secret-redacted** — values like tokens/passwords appear as `‹redacted›`; never try
to recover or echo raw secrets):

```bash
python3 tools/keymap/keymap.py --json $ARGUMENTS
```

The JSON has: `top_commands`, `subcommands`, `alias_candidates` (long command lines
typed ≥3×), and `aliases` (each with `used` and `missed` = times the long form was
typed instead). `meta.since`/`meta.until` give the date span when history has timestamps.

If the tool errors (no history found), say so plainly and stop.

## 2. Read the current setup

Before suggesting anything, know what already exists — don't propose what's there:

- `zsh/.zshrc` and `pwsh/profile.ps1` — existing aliases, functions, keybindings, vi-mode
- `tools/cheat-py/cheat.tsv` — the learn-the-terminal entries (a new shortcut worth teaching belongs here too)
- `wezterm/wezterm.lua`, `zed/keymap.json`, `nvim/`, `starship/starship.toml` — other keyboard surfaces
- `CLAUDE.md` — the standing goals every change must serve

## 3. Reason, then propose

Find changes that are **justified by the data** and serve the repo's goals
(keyboard-first, stay simple, identical on both OSes, teach the why). Look for:

- **Missed aliases** — `aliases[].missed > 0`: the user keeps typing the long form. Surface it (maybe the alias name is awkward, or worth a `cheat` reminder).
- **Alias candidates** — frequent, long command lines with no alias yet → propose a short one. Pick a name that fits the existing scheme.
- **Unused aliases** — defined but `used == 0`: dead weight, or a binding they forgot. Suggest removing or resurfacing via `cheat`.
- **Tool nudges** — heavy literal `cd` into the same dirs → they're underusing `zoxide` (`z`); lots of history re-runs → `Ctrl+R`/Atuin; a dominant subcommand → a focused alias.
- **Workflow gaps** — a busy command with no keybinding, an ergonomic win the goals call for.

Do **not** invent needs the data doesn't support (goal #2: stay simple, no speculation).
A short, high-confidence list beats an exhaustive one.

## 4. Present for approval — then apply

Show a **prioritized** list. For each item: the **evidence** (quote the number, e.g.
"you typed `cd ..` 4× but `..` exists"), the **proposed change** (the exact diff), and
the **why** (which goal it serves; any trade-off). Group by file.

Then **ask before editing.** On approval, apply the changes — and respect the repo's
rules:

- **Cross-platform parity (goal #3):** a shell change goes in *both* `zsh/.zshrc` and `pwsh/profile.ps1` unless the OS forces a fork — say so if it does.
- **Teach it (goal #5):** when you add a shortcut, add or update the matching `cheat.tsv` entry so it's discoverable.
- Match surrounding style and comment density. Don't touch the install scripts unless a change adds a new linked file.
- Note that config files are symlinked into the repo, so edits are live immediately — no reinstall.

Keep the tone of a coach, not a linter: this is the user's own usage reflected back,
with the smallest changes that make tomorrow's terminal faster than today's.
