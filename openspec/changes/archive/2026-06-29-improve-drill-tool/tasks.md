## 1. Remove scheduling, persistence, and the nudge

- [x] 1.1 Strip the Leitner/due-date machinery from `drills/drill.js`: remove `INTERVALS`/`MAX_BOX`, the box+due math in `grade`, `isDue`/`dueCards`, `addDaysYMD`/`todayYMD`, `loadProgress`/`saveProgress`/`stateFile`, and `countDue`/`--count`
- [x] 1.2 Select the session's cards from the whole deck (optionally filtered by category) instead of by due date; grades become session-only counters with nothing persisted
- [x] 1.3 Remove the `--count` startup nudge from `zsh/.zshrc` and `pwsh/profile.ps1`, keeping only the node-guarded `learn` alias/function
- [x] 1.4 Remove the now-unused `drills/progress.json` entry from `.gitignore`

## 2. Session UX

- [x] 2.1 Add a skip action (`s`) at the grade prompt that advances to the next card and counts it as skipped (not graded)
- [x] 2.2 Match grade-prompt input against an explicit allow-set (`g`/`m`/`s`/`q`) so arrow keys and other multi-byte sequences are ignored rather than treated as a grade
- [x] 2.3 Track `gotIt`, `missed`, and `skipped` counters and print a single end-of-session summary line (reviewed / got it / missed / skipped, out of the session's card count)
- [x] 2.4 Make the grade prompt text advertise the skip key

## 3. Origin and category columns

- [x] 3.1 Add `origin` and `category` columns to the `drills/deck.tsv` header and parse them in `loadDeck` (the card object gains `origin` and `category` fields)
- [x] 3.2 Backfill `origin` (`custom` or `builtin`) for every existing card, checking each reveal against its source config to classify it correctly
- [x] 3.3 Backfill `category` (a kebab-case topic such as navigation/search/panes/git) for every existing card
- [x] 3.4 Render origin and category in the session display (e.g. a `[<tool> · <category> · <origin>]` tag on the card header)
- [x] 3.5 Add an optional positional category argument to `runSession` so `learn <category>` restricts the session to cards in that category (exact, case-insensitive); an unknown category reports nothing rather than falling back to the whole deck

## 4. Tests

- [x] 4.1 Add `drills/drill.test.js` using `node:test` + `node:assert` that imports the runner's exported internals; give `loadDeck` an optional path parameter so the test can point it at a temp fixture
- [x] 4.2 Test that `loadDeck` parses the `origin` and `category` fields and skips rows with the wrong column count or a blank required field
- [x] 4.3 Test that `loadDeck` returns `[]` for a missing deck file
- [x] 4.4 Test that the category filter selects only matching cards (case-insensitive) and returns nothing for an unknown category
- [x] 4.5 Confirm the suite runs via `node --test drills/` with no extra dependency

## 5. Grow the deck

- [x] 5.1 Add curated cards to `drills/deck.tsv` covering more WezTerm, zsh, Starship, and zoxide features, with reveals grounded in the actual config files and each card's `origin` and `category` set
- [x] 5.2 Add cards for the newer Linux setup (keyd remapper, COSMIC-on-niri) where a learnable keybinding/command exists, with `origin` and `category` set
- [x] 5.3 Re-check every new reveal against its source config so no answer is stale, and keep category names consistent (reuse existing topics rather than inventing near-duplicates)

## 6. Wire into setup

- [x] 6.1 Add a `node` row to `setup/tools.tsv` following the existing schema (`name`, `linux_source`, `scoop_pkg`, `changelog_url`, `desc`, `manage`, `platform`) and a matching `install_node` to `setup/lib.sh`, confirming no existing row already installs Node
- [x] 6.2 Verify `zsh/.zshrc` and `pwsh/profile.ps1` drill blocks gate on Node presence and wire `learn` identically on both shells; fix any drift

## 7. Docs

- [x] 7.1 Rewrite `docs/drills.md` to drop scheduling/due/nudge/progress and document the flashcard runner, the skip key, the end-of-session summary, the `origin` column (custom vs built-in) and how to classify it, the `category` column and `learn <category>` filtering, and Node as a tracked setup dependency

## 8. Verify

- [x] 8.1 Run `node --test drills/` and confirm all tests pass
- [x] 8.2 Run `learn` end-to-end on zsh: grade, skip, quit, and confirm the summary, the origin/category tag, `learn <category>` filtering (including an unknown category), and the empty-deck path all behave per spec
