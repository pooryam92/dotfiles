## Context

This repo is a cross-platform terminal environment (Linux + Windows) with ~11
tools, each already documented in `docs/`. The owner has working knowledge but
keeps discovering features they never knew existed. A previous learning aid — a
once-a-day startup tip inside a 1,820-line Python + Textual suite (cheat sheet,
keymap usage-heatmap, TUI browser, `/keymap` command) — was removed in `40461fd`
for being passive, easy to tune out, and the repo's only Python dependency
(venv + Textual install). The standing goals constrain the replacement: better
keyboard fluency (#1), stay simple / prefer built-ins (#2), one experience on both
OSes (#3), teach as we go (#5).

The key reframe from exploration: the real gap is **unknown unknowns** — features
the user has never encountered. This is invisible to usage detection (you can't act
"slowly" on a feature you don't know), so the model must be **exposure**, not
**correction**. And passive exposure (a tip you read) is the weakest form of
learning and is exactly what failed before. The strong form is a **challenge**:
present a task, let the user attempt it and discover the feature, then reveal —
active recall, self-paced, no "wrong moment."

## Goals / Non-Goals

**Goals:**
- Surface unknown-unknown features through active drills, not passive tips.
- Make learning stick via active recall + spaced repetition.
- Self-paced (pull) so there is no intrusive-timing problem; the only push is a
  rare, content-free "cards are due" count.
- One runner for both OSes; no new runtime; small, well-commented surface.
- Track progress per machine so the deck never repeats what's mastered.

**Non-Goals:**
- No usage/history parsing or heatmap (that was v1's complexity and can't see
  unknown unknowns anyway).
- No TUI framework, no Python, no daemon, no background process.
- Not a full SRS engine (no SM-2/Anki math) — Leitner boxes are enough.
- Not auto-graded execution of challenges — the user self-reports got it / missed.
  (We can't reliably observe a keypress inside WezTerm or Neovim from a script.)

## Decisions

**D1 — Active drills over passive tips.** Tips failed because reading is passive and
can't reveal unknown unknowns to *you*. A "can you do X?" challenge makes the gap
visible (you discover you didn't know how) and forces recall. Alternative (smarter
tip feed) rejected: same passive failure mode the user already bounced off.

**D2 — Single `drill.js` on Node, not two shell scripts.** Node is already a
dependency (Claude Code; `claude/statusline.js` is JS), so this adds no new runtime
and gives **one** cross-platform file — the same win `wezterm.lua` provides over a
zsh/pwsh fork (Goal #3). Alternative (zsh + pwsh scripts) rejected: two files to
keep in sync, the exact drift Goal #3 fights. Python rejected outright: it's what
sank v1 (venv + only Python dep).

**D3 — Leitner boxes for scheduling.** A card answered "got it" advances a box and
its next-due date pushes out (e.g. boxes → 1d, 3d, 7d, 21d, 60d); a miss resets to
box 1. ~10 lines, no floating-point intervals. Alternative (SM-2/Anki) rejected as
over-engineered for a personal deck of dozens of cards.

**D4 — Deck as a TSV in the repo.** `drills/deck.tsv` with columns
`id  tool  task  reveal` (TSV matches the repo's existing `setup/*.tsv` convention).
Versioned and curated (the "hybrid" content choice); easy to grow by hand.
Alternative (JSON / per-tool markdown) rejected: heavier to hand-edit than a TSV.

**D5 — Progress state outside git, per machine.** A JSON file mapping
`id → {box, due}`, under the OS state dir (`$XDG_STATE_HOME` or
`~/.local/state/dotfiles-drills/progress.json` on Linux; `%LOCALAPPDATA%` on
Windows), gitignored like `.zsh_history`. Progress is personal and machine-local;
committing it would create cross-machine merge noise.

**D6 — Pull-first, with a due-only nudge.** Primary entry is the `learn` command
(an alias in both shells). The only push is a single line printed at shell start
**only when** `due > 0` — a count, never content — and silent otherwise. This
rescues the one good thing about a nudge (it reminds you to engage) while removing
what made the daily tip fail (it interrupted with content at the wrong moment).
Alternative (Starship segment showing due count) deferred to Open Questions — nice
but more moving parts; the shell-start line is the MVP.

**D7 — Self-graded reveal, not auto-detection.** The runner shows the task, the
user goes and tries it in the real tool, presses a key to reveal the answer, then
reports got it / missed. We deliberately do **not** try to observe whether they
pressed `Alt+z` — that's unobservable across WezTerm/Neovim/etc. and would drag in
exactly the complexity we're avoiding.

## Risks / Trade-offs

- **Self-grading can be gamed** (you mark "got it" without really learning) →
  Mitigation: it only hurts the user; the task wording asks them to *actually do it
  in the tool first*, and missed cards resurface fast.
- **The due-only nudge could still become wallpaper** → Mitigation: it appears only
  when cards are due and is one short line; if it grows annoying, a frequency cap
  (max once/day) or moving it to `learn`-only is a trivial follow-up.
- **Node assumed present** → Mitigation: it's installed via Claude Code on both
  installers; the nudge and alias guard on `command -v node` (and the Windows
  equivalent) so a missing Node degrades to silence, never an error.
- **Deck staleness** (a `reveal` answer drifts from the real keybinding) →
  Mitigation: keep the deck small and tool-grouped; cards reference the config, and
  it's reviewed alongside config changes (same discipline as `docs/`).
- **Scope creep back toward v1** → Mitigation: Non-Goals fence it; the whole thing
  is one TSV + one JS file + a few lines per shell.

## Migration Plan

Purely additive — no removals, nothing to roll back beyond deleting the new files
and reverting the shell-profile and `.gitignore` edits. Ships behind an explicit
`learn` command; the nudge only appears once the deck and state exist. Update both
installers/links only if the runner is symlinked rather than aliased (D2 leans
toward a shell alias to keep `setup/links.tsv` untouched).

## Open Questions

- **Exact Leitner intervals** — start with 1d/3d/7d/21d/60d? Tunable later.
- **Command name** — `learn` vs `drill`. Leaning `learn`.
- **Runner install** — shell alias (no new symlink) vs symlink into `~/.local/bin`
  / Windows shim. Alias is simpler and cross-platform; lean alias.
- **Starship "N due" segment** — worth adding after the MVP, or noise?
- **Cards for in-app features** (Neovim motions, Zed) — include from day one or
  start with shell/terminal-observable tools? Lean: seed daily-drivers first.
