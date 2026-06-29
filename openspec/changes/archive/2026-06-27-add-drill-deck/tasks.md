## 1. Deck content

- [x] 1.1 Create `drills/deck.tsv` with header `id  tool  task  reveal`
- [x] 1.2 Seed WezTerm cards (copy mode `Ctrl+s`, pane zoom `Alt+z`, rotate panes `Alt+Shift+[`/`]`, resize `Alt+Shift+HJKL`)
- [x] 1.3 Seed zsh cards (vi command-line mode, `Ctrl+E`/`Ctrl+F` accept suggestion, `Ctrl+R`/`Ctrl+T`/`Alt+C` fzf, AUTO_CD, space-prefix to skip history)
- [x] 1.4 Seed zoxide (`z`, `zi`) and Starship (read the vi-mode prompt symbol) cards
- [x] 1.5 Sanity-check every `reveal` against the actual config so no card is stale

## 2. Runner (drill.js)

- [x] 2.1 Create `drills/drill.js`; resolve the deck path relative to the script and parse the TSV
- [x] 2.2 Resolve the per-machine state path (`$XDG_STATE_HOME`/`~/.local/state` on Linux, `%LOCALAPPDATA%` on Windows); load or initialize `progress.json`
- [x] 2.3 Implement Leitner scheduling: box→interval table, select due + never-seen cards, advance on "got it", reset on "missed"
- [x] 2.4 Implement the interactive loop: show task → keypress → reveal → self-grade; handle the empty/nothing-due case
- [x] 2.5 Add a `--count` (or equivalent) mode that prints only the number of due cards, for the nudge
- [x] 2.6 Write the updated boxes/due dates back to the state file

## 3. Shell integration

- [x] 3.1 Add the `learn` alias to `zsh/.zshrc`, guarded on `command -v node`
- [x] 3.2 Add the `learn` alias to `pwsh/profile.ps1`, guarded on node availability
- [x] 3.3 Add the due-only nudge to `zsh/.zshrc` (print one line only when `--count` > 0; silent otherwise)
- [x] 3.4 Add the matching due-only nudge to `pwsh/profile.ps1`
- [x] 3.5 Add the progress-state path to `.gitignore`

## 4. Docs

- [x] 4.1 Write `docs/drills.md` — what the deck is, how `learn` works, how to add cards, where state lives
- [x] 4.2 Add a "Learn it" entry for drills in `README.md`

## 5. Verify

- [x] 5.1 Run `learn` on Linux: new cards appear, reveal works, grading updates state, due count drops
- [x] 5.2 Confirm the shell-start nudge appears only when cards are due and is silent otherwise
- [x] 5.3 Confirm the state file is gitignored and the runner errors cleanly if the deck is missing
- [x] 5.4 Cross-platform smoke check on Windows (alias + nudge), or note it as a follow-up if no Windows machine is at hand
