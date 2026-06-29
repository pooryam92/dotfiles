## 1. Runner robustness

- [ ] 1.1 Harden `loadDeck` in `drills/drill.js` to skip rows that don't have the full set of non-empty fields (`id`, `tool`, `task`, `reveal`, `origin`, `category`) and to return `[]` for a missing or empty deck file
- [ ] 1.2 Confirm `loadProgress` returns `{}` on corrupt/partial JSON (already does) and that `countDue` swallows all errors and prints `0`; adjust if any path can still throw
- [ ] 1.3 Verify the shell-start `--count` nudge stays silent (prints `0`, no stderr) when the deck or state file is broken

## 2. Session UX

- [ ] 2.1 Add a skip action (`s`) at the grade prompt that advances to the next card without writing any progress for the current card (box/due unchanged)
- [ ] 2.2 Match grade-prompt input against an explicit allow-set (`g`/`m`/`s`/`q`) so arrow keys and other multi-byte sequences are ignored rather than treated as a grade
- [ ] 2.3 Track `gotIt`, `missed`, and `skipped` counters and print a single end-of-session summary line (reviewed / got it / missed / skipped / due remaining)
- [ ] 2.4 Update the grade prompt text to advertise the skip key

## 3. Tests

- [ ] 3.1 Add `drills/drill.test.js` using `node:test` + `node:assert` that imports the runner's exported internals
- [ ] 3.2 Test that "got it" advances the box by one, caps at the max box, and pushes the due date out per the box interval
- [ ] 3.3 Test that "missed" resets the card to box 1 and makes it due immediately
- [ ] 3.4 Test that `dueCards`/`isDue` count a never-seen card as due
- [ ] 3.5 Test that `loadDeck` parses the `origin` and `category` fields and skips rows missing them
- [ ] 3.6 Test that filtering by category selects only matching due cards (and returns nothing for an unknown category)
- [ ] 3.7 Confirm the suite runs via `node --test drills/` with no extra dependency

## 4. Origin and category columns

- [ ] 4.1 Add `origin` and `category` columns to the `drills/deck.tsv` header and parse them in `loadDeck` (the card object gains `origin` and `category` fields)
- [ ] 4.2 Backfill `origin` (`custom` or `builtin`) for every existing card, checking each reveal against its source config to classify it correctly
- [ ] 4.3 Backfill `category` (a kebab-case topic such as navigation/search/panes/git) for every existing card
- [ ] 4.4 Render origin and category in the session display (e.g. a `[<tool> · <category> · <origin>]` tag on the card header)
- [ ] 4.5 Add an optional positional category argument to `runSession` so `learn <category>` restricts the session to due cards in that category (exact, case-insensitive); keep the `--count` nudge global

## 5. Grow the deck

- [ ] 5.1 Add curated cards to `drills/deck.tsv` covering more WezTerm, zsh, Starship, and zoxide features, with reveals grounded in the actual config files and each card's `origin` and `category` set
- [ ] 5.2 Add cards for the newer Linux setup (keyd remapper, COSMIC-on-niri) where a learnable keybinding/command exists, with `origin` and `category` set
- [ ] 5.3 Re-check every new reveal against its source config so no answer is stale, and keep category names consistent (reuse existing topics rather than inventing near-duplicates)

## 6. Wire into setup

- [ ] 6.1 Add a `node` row to `setup/tools.tsv` following the existing schema (`name`, `linux_source`, `scoop_pkg`, `changelog_url`, `desc`, `manage`, `platform`), confirming no existing row already installs Node
- [ ] 6.2 Verify `zsh/.zshrc` and `pwsh/profile.ps1` drill blocks already gate on Node presence and wire `learn` + the nudge identically on both shells; fix any drift

## 7. Docs

- [ ] 7.1 Update `docs/drills.md` to document the skip key, the end-of-session summary, the `origin` column (custom vs built-in) and how to classify it, the `category` column and `learn <category>` filtering, and Node as a tracked setup dependency

## 8. Verify

- [ ] 8.1 Run `node --test drills/` and confirm all tests pass
- [ ] 8.2 Run `learn` end-to-end on zsh: grade, skip, quit, and confirm the summary, the origin/category tag, `learn <category>` filtering (including an unknown category), and a corrupt-state/empty-deck path all behave per spec
