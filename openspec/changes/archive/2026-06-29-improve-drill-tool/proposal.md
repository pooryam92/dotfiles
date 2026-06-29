## Why

The drill tool (`learn`) shipped as a working first cut, but two problems showed up
in use. First, the **spaced-repetition scheduling is not useful here**: this is a
small personal deck of one's own tools, and the Leitner boxes / per-machine due
dates mostly got in the way — cards you wanted to review were "not due yet", a
shell-start nudge counted "due" cards you'd often ignore, and a hidden state file
made behavior depend on invisible history. Second, what *is* useful — the deck and
the active-recall session — is thin and fragile: the deck is tiny, the runner has no
tests, the session flow can't skip or recover from stray keys, and Node (the runtime
the whole feature depends on) is never installed or checked by the setup scripts.

This change **drops the scheduling entirely** and hardens what's left into a simple,
trustworthy flashcard runner: every card is fair game every session, you pull a
session whenever you want, and the deck and runner grow sturdier.

## What Changes

- **Remove the due-date / spaced-repetition machinery**: Drop the Leitner boxes,
  next-due dates, the per-machine `progress.json` state file, the "only show due
  cards" selection, and the due-only shell-start nudge. `learn` becomes a plain
  flashcard runner over the whole deck.
- **Session UX**: Keep the active-recall flow (show task → reveal on keypress →
  self-grade) but make it sturdier — allow skipping a card, show a one-line
  end-of-session summary (reviewed / got it / missed / skipped), and make key
  handling tolerate arrow keys and other multi-byte sequences instead of mistaking
  them for a grade. The grade is a session-only tally now (nothing is persisted).
- **Tests + robustness**: Add a test for `drill.js` covering deck parsing and the
  category filter. Harden against malformed TSV rows (wrong column count, blank
  fields) and a missing/empty deck — none should crash a session.
- **Grow the deck**: Expand `deck.tsv` with more curated cards across the repo's
  tools (WezTerm, zsh, Starship, zoxide, and the newer keyd / niri setup), keeping
  reveals grounded in the actual config.
- **Label each card's origin**: Add an `origin` column to the deck marking whether a
  card's feature is **custom** (configured in this repo's dotfiles — won't exist on a
  vanilla install) or **built-in** (a tool default that works out of the box), and
  surface that label in the session so the learner knows what depends on this config.
- **Group cards by category**: Add a `category` column tagging each card with a topic
  (e.g. navigation, search, panes, git) independent of its owning tool, surface it in
  the session, and let `learn <category>` run a session restricted to one category.
- **Wire into setup**: Add Node as a tracked dependency in `setup/tools.tsv` (with a
  matching install step) so a fresh machine gets the runner's runtime, and confirm
  the `learn` alias is wired identically on both zsh and PowerShell.

## Capabilities

### New Capabilities
<!-- None — this change modifies the existing tool-drills capability. -->

### Modified Capabilities
- `tool-drills`: Remove the spaced-repetition scheduling, per-machine progress
  persistence, and due-only shell-start nudge. Reframe the session as a flashcard
  runner over the whole deck (no due gating) with richer controls (skip +
  end-of-session summary + tolerant key handling). Extend the deck schema with an
  `origin` column (custom vs built-in) and a `category` column that the session
  surfaces, plus an optional category filter on the session. Add requirements for
  runner correctness being test-covered, graceful degradation on malformed
  deck/runtime, and the runner's runtime (Node) being an installed, setup-tracked
  dependency on both platforms.

## Impact

- **Code**: `drills/drill.js` (remove scheduling/state, flashcard session loop, parse
  + display the new `origin` and `category` columns, optional `learn <category>`
  filter), a new test file for the runner, `drills/deck.tsv` (more cards + new
  `origin` and `category` columns on every row).
- **Setup**: `setup/tools.tsv` + `setup/lib.sh` (Node entry + `install_node`);
  `zsh/.zshrc` and `pwsh/profile.ps1` drill blocks lose the nudge and keep only the
  `learn` alias; `.gitignore` drops the now-unused `drills/progress.json` entry.
- **Docs**: `docs/drills.md` (rewrite: flashcard runner, skip key, summary,
  origin/category columns, `learn <category>`, Node dependency — no scheduling).
- **Dependencies**: Node.js becomes an explicitly tracked install dependency rather
  than an assumed-present one.
- **Cross-platform**: All behavior must hold on both Pop!_OS (zsh) and Windows
  (PowerShell); the runner stays a single shared implementation.
