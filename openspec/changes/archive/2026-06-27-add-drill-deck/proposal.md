## Why

I know *some* features of the tools in this repo but keep hitting **unknown
unknowns** — features I never reach for because I never knew they existed. Usage
detection can't help here: you can't type something "the slow way" for a feature
you've never heard of. The earlier fix (a once-a-day startup tip, part of a
1,820-line Python + Textual suite) was removed because it was passive, push-based
(easy to tune out), and far over the simplicity budget. We want active, spaced
**drills** instead of passive tips — and built from what's already in the stack.

## What Changes

- **Add a curated drill deck** — a versioned, hand-picked set of small "can you do
  X?" challenges, one per useful feature, covering the daily-driver tools first
  (WezTerm, zsh, Starship, zoxide) and growing later.
- **Add a `learn` runner** — a single cross-platform Node script (`drill.js`) that
  picks the cards that are *due*, shows the task, waits, reveals the answer on a
  keypress, and lets you self-grade (got it / missed). Node is already in the stack
  (Claude Code, `claude/statusline.js`), so this adds **no new runtime** — and one
  file serves both OSes, mirroring the `wezterm.lua` pattern (Goal #3).
- **Add spaced-repetition scheduling** — simple Leitner boxes: a card you get right
  moves to a longer interval; a miss resets it to box 1. ~10 lines of logic.
- **Persist progress outside git** — a per-machine state file (learned/box/due per
  card) so the deck never repeats what you've mastered. Gitignored, like
  `.zsh_history`.
- **Add a restrained, due-only nudge** — on shell start, *only when cards are due*,
  print a one-line count (e.g. `🎴 4 drills due — run learn`) and nothing
  otherwise. This is the anti-daily-tip: rare, content-free, and it points you to
  *pull* rather than shoving a fact at you. Added to both `zsh/.zshrc` and
  `pwsh/profile.ps1`.
- **Document it** — a `docs/drills.md` guide and a README "Learn it" entry.

## Capabilities

### New Capabilities
- `tool-drills`: a spaced-repetition drill deck for learning the repo's own tools —
  curated challenges, an active reveal-and-grade runner, Leitner scheduling,
  per-machine progress, and a due-only shell nudge.

### Modified Capabilities
<!-- None: there are no existing specs in openspec/specs/. This is purely additive. -->

## Impact

- **New files**: `drills/deck.tsv` (content), `drills/drill.js` (runner),
  `docs/drills.md` (guide).
- **Edited files**: `zsh/.zshrc` and `pwsh/profile.ps1` (the `learn` alias + the
  due-only nudge), `.gitignore` (the progress-state path), `README.md` (Learn-it
  entry), and possibly `setup/links.tsv` if the runner is symlinked rather than
  aliased.
- **Dependencies**: Node, already present via Claude Code — **no new runtime**, no
  venv (the thing that sank the previous Python tooling).
- **State**: a new per-machine progress file under the OS state dir
  (`~/.local/state/...` on Linux, `%LOCALAPPDATA%\...` on Windows); never committed.
- **Goals**: serves Goal #1 (better keyboard fluency), Goal #5 (teach as we go);
  honors Goal #2 (no new runtime, small surface) and Goal #3 (one runner, both OSes).
