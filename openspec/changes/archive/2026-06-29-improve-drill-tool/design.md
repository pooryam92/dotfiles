## Context

`drills/drill.js` is a cross-platform Node script with no tests, a 14-card deck, and
a session loop that reads single keypresses in raw mode. As shipped it scheduled
cards with Leitner boxes and per-machine due dates, persisted progress to a
`progress.json` under the OS state dir, only showed "due" cards, and printed a
due-only nudge at shell start. In practice the scheduling added friction for a tiny
personal deck without earning its complexity, so this change removes it. Node is
assumed present (it ships with Claude Code) but is not listed in `setup/tools.tsv`,
so a fresh machine that lacks Node loses the feature silently.

The repo's standing goals apply: stay simple (no new runtime, no test framework), one
shared experience on both OSes, and well-commented small config over abstractions.

## Goals / Non-Goals

**Goals:**
- `learn` is a plain flashcard runner over the whole deck — no scheduling, no hidden
  state. Every card is available every session; an optional category narrows it.
- The deck parsing and category filter are covered by an automated test that runs
  with plain Node and no extra dependency.
- Bad inputs (malformed TSV rows, missing/empty deck) degrade gracefully instead of
  crashing the session.
- The session loop supports skip, prints an end-of-session summary, and ignores stray
  multi-byte keys at the grade prompt.
- The deck grows with grounded cards covering more of the repo's tools.
- Node is a tracked install dependency on both platforms.

**Non-Goals:**
- No spaced repetition of any kind (Leitner, SM-2, Anki) — removed, not replaced.
- No persisted progress / state file — the grade is a session-only tally.
- No shell-start nudge — `learn` is pull-only, run it when you want.
- No new test framework, bundler, or runtime.

## Decisions

**Remove scheduling, persistence, and the nudge.**
Drop `INTERVALS`/box logic, `grade()`'s due-date math, `isDue`/`dueCards`,
`loadProgress`/`saveProgress`/`stateFile`, and `countDue`/`--count`. The session
selects from the whole deck (optionally filtered by category) and grades are counted
for the summary only, never written anywhere. Rationale: for a personal deck of dozens
of cards the scheduling cost (invisible state, "not due yet" gating, a nudge that's
easy to tune out) outweighs its benefit; a simple "drill me now" loop matches how the
tool is actually used. The `zsh/.zshrc` and `pwsh/profile.ps1` blocks keep only the
node-guarded `learn` alias; the `.gitignore` entry for `progress.json` is removed since
the file is no longer created.

**Session is a flashcard loop with a session-only grade.**
For each card: show the task, reveal on a keypress, then take `g`/`m`/`s`/`q`. `g`/`m`
just increment counters for the end-of-session summary; `s` skips without counting a
grade; `q` quits. There is no consequence to a grade beyond the tally — active recall
is the value, and the summary gives a sense of how the session went.

**Skip = a third action at the grade prompt.**
Add an `s` key that advances to the next card and counts it as skipped (not graded).
Rationale: lets the user move past a card they don't want to grade without it landing
in the got-it / missed tally.

**Tolerant key handling at the grade prompt.**
Match the full key string against an explicit allow-set (`g`/`m`/`s`/`q`), treat
Ctrl+C as exit, and ignore everything else — so a multi-byte escape sequence (arrow
key) can't be mistaken for a grade. Makes the tolerance explicit and test-describable.

**Card origin as a fifth TSV column.**
Add an `origin` column with two values: `custom` (configured in this repo — won't
exist on a vanilla install) or `builtin` (a tool default). Rationale: the distinction
is exactly what makes a tip actionable — "did *I* set this up, or does the tool do it
by default?" A column keeps it data-driven (no code change to add a card) and lets the
session render a short tag. Authoring rule: if the reveal points at a keybinding/setting
that lives in `wezterm/wezterm.lua`, `zsh/.zshrc`, `starship/starship.toml`,
`niri/config.kdl`, the keyd map, etc., it's `custom`; if it works on a fresh install of
the tool, it's `builtin`.

**Category as a sixth TSV column + an optional session filter.**
Add a `category` column tagging each card with a free-form kebab-case topic
(navigation, search, panes, git, prompt, …) that cuts across tools — e.g. WezTerm
pane-rotation and niri window-focus are both `navigation`. Rationale: tools are how
features are *implemented*; categories are how the learner *thinks* ("drill me on
navigation"), which directly serves the keyboard-navigation learning goal.
`runSession` takes an optional positional category arg: `learn <category>` restricts
the session to cards in that category (exact, case-insensitive match); no arg = the
whole deck. Unknown category → a "nothing in that category" message rather than a
silent fallback to all cards.

**Robust deck loading + a testable seam.**
`loadDeck(deckPath?)` filters rows to those with the full set of non-empty fields
(`id`, `tool`, `task`, `reveal`, `origin`, `category`) and skips the rest; an
empty/missing deck yields `[]`. The optional `deckPath` parameter (default: the repo's
`deck.tsv`) lets the test point `loadDeck` at a temp fixture, so parsing and row-skipping
are covered without an interactive session. `sessionCards(deck, category)` is a pure
function, also directly testable.

**Node added to `setup/tools.tsv` + `install_node`.**
Track Node as a dependency in the data-driven manifest so `install.sh` installs it
(the install loop requires a matching `install_<name>`, so add `install_node` to
`setup/lib.sh`) and the Windows scoop list picks it up via `scoop_pkg`. `install_node`
guards on `command -v node` so it's a no-op when Node is already present (e.g. shipped
by Claude Code).

**End-of-session summary.**
Track `gotIt`, `missed`, `skipped` counters and print one line on exit (reviewed / got
it / missed / skipped, out of the session's card count). One line, to respect the
tool's quiet ethos.

## Risks / Trade-offs

- **Losing scheduling means no "what to review next" guidance** → acceptable and
  intended: the deck is small enough to run end-to-end, and `learn <category>` covers
  the "focus on X" need that boxes were a poor proxy for.
- **tools.tsv / install schema mismatch** → mirror an existing row and an existing
  `install_<name>` exactly (read both first) rather than inventing columns or steps.
- **`node:test` availability on older Node** → stable since Node 18; the stack ships
  current Node, so acceptable. If absent, the runner itself is unaffected.
- **Deck-row filtering hides typos** → silently skipping malformed rows could mask a
  real authoring mistake. Mitigation: the test (and manual `learn`) show a lower card
  count; acceptable for a hand-edited personal deck.

## Migration Plan

Removing scheduling needs no data migration: existing `progress.json` files simply
become unused (the runner no longer reads or writes them) and can be deleted; the
`.gitignore` entry is dropped. Adding Node to `setup/tools.tsv` is additive. New deck
cards just appear in every session.

## Open Questions

- None outstanding. (Node is confirmed not already installed by another `tools.tsv`
  row, so the new entry is not a duplicate.)
