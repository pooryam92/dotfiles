## Context

`drills/drill.js` is a ~180-line cross-platform Node script with no tests, a 14-card
deck, and a session loop that reads single keypresses in raw mode. It already wires
`learn` and a due-only nudge into both `zsh/.zshrc` and `pwsh/profile.ps1`. Node is
assumed present (it ships with Claude Code) but is not listed in `setup/tools.tsv`,
so a fresh machine that lacks Node loses the feature silently.

This change hardens what exists rather than redesigning it. The repo's standing goals
apply: stay simple (no new runtime, no test framework), one shared experience on both
OSes, and well-commented small config over abstractions.

## Goals / Non-Goals

**Goals:**
- The runner's scheduling/grading logic is covered by an automated test that runs
  with plain Node and no extra dependency.
- Bad inputs (corrupt state, malformed TSV rows, missing/empty deck) degrade
  gracefully instead of crashing the session or the shell nudge.
- The session loop supports skip, prints an end-of-session summary, and ignores stray
  multi-byte keys at the grade prompt.
- The deck grows with grounded cards covering more of the repo's tools.
- Node is a tracked install dependency on both platforms.

**Non-Goals:**
- No SM-2/Anki-grade scheduling — the Leitner boxes stay.
- No new test framework, bundler, or runtime.
- No redesign of the state-file location or the deck's TSV format/columns.
- No change to the nudge's content contract (count-only, silent when nothing due).

## Decisions

**Test with `node:test` + `node:assert`, no framework.**
`drill.js` already exports its internals (`grade`, `dueCards`, `isDue`,
`addDaysYMD`, …). A single `drills/drill.test.js` using the built-in `node:test`
runner exercises them and runs via `node --test`. Rationale: zero new dependency, no
package.json churn, matches the "Node is already in the stack" reasoning the runner
itself uses. Alternative considered: shelling the script end-to-end — rejected as
brittle (raw-mode stdin) and slower; unit-testing the pure functions covers the
scheduling/grading requirements directly.

**Skip = a third grade action that leaves schedule untouched.**
Add a `s` key at the grade prompt. Unlike "missed", skip writes nothing to progress
for that card, so its box/due are unchanged and it remains due. Rationale: lets the
user move past a card they don't want to grade yet without polluting their schedule.

**Tolerant key handling at the grade prompt.**
The current loop accepts only `g`/`m`/`q` and silently re-loops on anything else,
which is already mostly correct — but a multi-byte escape sequence (arrow key) can
arrive whose first byte happens to match nothing, or future keys could collide.
Decision: match on the full key string against an explicit allow-set
(`g`/`m`/`s`/`q`), treat Ctrl+C as exit (already handled), and ignore everything
else. This makes the tolerance explicit and test-described rather than incidental.

**Card origin as a fifth TSV column.**
Add an `origin` column with two values: `custom` (configured in this repo —
won't exist on a vanilla install) or `builtin` (a tool default). Rationale: the
distinction is exactly what makes a tip actionable — "did *I* set this up, or does
the tool do it by default?" A column keeps it data-driven (no code change to add a
card) and lets the session render a short tag (e.g. `[WezTerm · custom]`). Default
when authoring: if a reveal points at a keybinding/setting that lives in
`wezterm/wezterm.lua`, `zsh/.zshrc`, `starship/starship.toml`, the keyd map, etc.,
it's `custom`; if it works on a fresh install of the tool, it's `builtin`.
Alternative considered: encoding origin inside the `tool` column (e.g.
`WezTerm*`) — rejected as cryptic and harder to filter/validate.

**Category as a sixth TSV column + an optional session filter.**
Add a `category` column tagging each card with a free-form kebab-case topic
(navigation, search, panes, git, prompt, …) that cuts across tools — e.g. WezTerm
pane-rotation and niri window-focus are both `navigation`. Rationale: tools are how
features are *implemented*; categories are how the learner *thinks* ("drill me on
navigation"), which directly serves the keyboard-navigation learning goal.
`runSession` takes an optional positional category arg: `learn <category>` filters
due cards to that category (exact, case-insensitive match); no arg = all due. The
arg is distinct from the existing `--count` flag, so the nudge stays global (counts
all due cards, not per-category). Unknown category → the normal "nothing due"
message scoped to that category. Alternative considered: multiple tags per card —
rejected as over-engineered for a personal deck; one category per card keeps
authoring and filtering trivial, and a card that fits two topics can pick the
dominant one.

**Robust deck/state loading.**
`loadDeck` filters rows to those with the full set of non-empty fields
(`id`, `tool`, `task`, `reveal`, `origin`, `category`) and skips the rest; an
empty/missing deck yields `[]`. `loadProgress` already returns `{}` on parse failure — keep that.
`countDue` already swallows errors and prints `0`. These keep the shell nudge from
ever erroring on a broken file.

**Node added to `setup/tools.tsv`.**
Track Node as a dependency in the data-driven manifest so `install.sh` / the pwsh
setup install it. The exact install mechanism follows the existing tools.tsv schema
(reuse whatever package-manager columns the manifest already defines). Verify
`zsh/.zshrc` and `pwsh/profile.ps1` already gate on Node presence (they do — both
`--count` calls are wrapped to fail silent), so no shell change is expected.

**End-of-session summary.**
Track `gotIt`, `missed`, `skipped` counters alongside `reviewed` and print one line
on exit. Replaces the current single "Reviewed N" line. Keeps output to one line to
respect the tool's quiet ethos.

## Risks / Trade-offs

- **tools.tsv schema mismatch** → Before editing, read the manifest header and an
  existing multi-platform row; mirror that exact format for the Node entry rather
  than inventing columns.
- **`node:test` availability on older Node** → It's stable since Node 18; the stack
  ships current Node, so acceptable. If absent, the runner itself is unaffected
  (test is separate) — note it in docs.
- **Skip key discoverability** → Update the grade prompt text and `docs/drills.md`
  so `s` is documented; an undocumented key is effectively invisible.
- **Deck-row filtering hides typos** → Silently skipping malformed rows could mask a
  real authoring mistake. Mitigation: the test (and manual `learn`) will show a lower
  card count; acceptable for a hand-edited personal deck.

## Migration Plan

No data migration. The progress state schema is unchanged, so existing
`progress.json` files keep working. Adding Node to `setup/tools.tsv` is additive. New
deck cards are never-seen, so they simply appear as due on next `learn`.

## Open Questions

- Does `setup/tools.tsv` already have a row that installs Node indirectly (e.g. via a
  tool that bundles it)? Confirm during implementation to avoid a duplicate entry.
