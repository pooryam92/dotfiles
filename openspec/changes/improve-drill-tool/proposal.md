## Why

The drill tool (`learn`) shipped as a working first cut, but it's fragile and thin:
the deck is tiny, the runner has no tests so a scheduling regression would pass
silently, the session flow can't skip or recover from stray keys, and Node — the
runtime the whole feature depends on — is never installed or checked by the setup
scripts. Hardening it now, while the design is fresh, keeps the feature trustworthy
enough to actually rely on for daily learning.

## What Changes

- **Tests + robustness**: Add a test for `drill.js` covering Leitner scheduling and
  grading (got-it advances/caps the box, missed resets to box 1, due selection
  includes never-seen cards). Harden against corrupt/partial state, malformed TSV
  rows (wrong column count, blank fields), and a missing/empty deck — none should
  crash a session or the shell-start nudge.
- **Session UX**: Improve the interactive flow — allow skipping a card without
  grading it, show an end-of-session summary (reviewed / got-it / missed / due
  remaining), and make key handling tolerate arrow keys and other multi-byte
  sequences instead of mistaking them for a grade.
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
- **Wire into setup**: Add Node as a tracked dependency in `setup/tools.tsv` so a
  fresh machine gets the runner's runtime, and confirm the `learn` alias + due-only
  nudge are verified on both zsh and PowerShell.

## Capabilities

### New Capabilities
<!-- None — this change extends the existing tool-drills capability. -->

### Modified Capabilities
- `tool-drills`: Add requirements for runner correctness being test-covered,
  graceful degradation on malformed deck/state/runtime, richer session controls
  (skip + end-of-session summary + tolerant key handling), and the runner's runtime
  (Node) being an installed, setup-tracked dependency on both platforms. Also extend
  the deck schema with an `origin` column (custom vs built-in) and a `category` column
  that the session surfaces, plus an optional category filter on the session.

## Impact

- **Code**: `drills/drill.js` (robustness, session UX, parse + display the new
  `origin` and `category` columns, optional `learn <category>` filter), a new test
  file for the runner, `drills/deck.tsv` (more cards + new `origin` and `category`
  columns on every row).
- **Setup**: `setup/tools.tsv` (Node entry); verification of `zsh/.zshrc` and
  `pwsh/profile.ps1` drill blocks (likely no change — both already wire `learn` and
  the nudge).
- **Docs**: `docs/drills.md` (document skip key, summary, and the Node dependency).
- **Dependencies**: Node.js becomes an explicitly tracked install dependency rather
  than an assumed-present one.
- **Cross-platform**: All behavior must hold on both Pop!_OS (zsh) and Windows
  (PowerShell); the runner stays a single shared implementation.
