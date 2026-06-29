## MODIFIED Requirements

### Requirement: Curated drill deck
The system SHALL provide a versioned, curated deck of drills stored in the repo,
where each drill describes one feature of one tool as a task to perform and the
answer to reveal. The deck SHALL be a TSV with the columns `id`, `tool`, `task`,
`reveal`, `origin`, and `category`, where `origin` records whether the feature is
**custom** (configured in this repo's dotfiles and absent from a vanilla install) or
**built-in** (a default of the tool that works out of the box), and `category` tags
the card with a topic (e.g. navigation, search, panes, git) independent of its owning
tool. The deck SHALL seed the daily-driver tools (WezTerm, zsh, Starship, zoxide)
first.

#### Scenario: Deck provides task-and-reveal challenges
- **WHEN** a maintainer opens the deck file
- **THEN** each line defines a unique `id`, the owning `tool`, a `task` phrased as a
  "can you do X?" challenge, the `reveal` answer (e.g. the keybinding or command),
  an `origin` of `custom` or `builtin`, and a `category` topic tag

#### Scenario: Deck is hand-editable and grows over time
- **WHEN** a maintainer adds a feature to learn
- **THEN** they can add one TSV line (including its `origin` and `category`) without
  touching the runner code

### Requirement: Active drill session
The system SHALL provide a `learn` command that runs a drill session over the deck:
for each card it SHALL show the task, wait for the user to attempt it, reveal the
answer only on an explicit keypress, and then record the user's self-graded result
(got it / missed) for that session only. The session SHALL consider the whole deck
(it does not gate cards by any schedule or persisted history). The user SHALL also be
able to **skip** the current card without grading it and to quit at any prompt. The
session SHALL ignore unrecognized input — including arrow keys and other multi-byte
escape sequences — at the grade prompt rather than treating it as a grade, and SHALL
end with a one-line summary of how many cards were reviewed, got right, missed, and
skipped. The session SHALL also surface each card's `origin` (custom vs built-in) and
its `category` so the user can tell whether the feature comes from this repo's config
or is a tool default and what topic it belongs to. The command SHALL accept an
optional category argument (`learn <category>`) that restricts the session to cards in
that category; with no argument it considers the whole deck. The command SHALL be
invokable from both the Linux (zsh) and Windows (PowerShell) shells.

#### Scenario: Running a drill session
- **WHEN** the user runs `learn`
- **THEN** the system shows a task, waits, reveals the answer on a keypress, and
  prompts the user to self-grade got it / missed

#### Scenario: Card origin and category are surfaced
- **WHEN** a card is shown during a session
- **THEN** the display indicates whether the card's feature is custom (this repo's
  config) or built-in (a tool default) and shows the card's category

#### Scenario: Session filtered by category
- **WHEN** the user runs `learn <category>`
- **THEN** the session presents only cards whose `category` matches that argument
  and ignores cards in other categories

#### Scenario: Unknown category requested
- **WHEN** the user runs `learn <category>` with a category that matches no cards
- **THEN** the system reports that nothing matches that category rather than
  erroring or falling back to the whole deck

#### Scenario: Skipping a card
- **WHEN** the user chooses to skip the current card
- **THEN** the card is counted as skipped (not graded) and the session advances to
  the next card

#### Scenario: Unrecognized input at the grade prompt
- **WHEN** the user presses an arrow key or another key that is not a recognized
  grade/skip/quit action at the grade prompt
- **THEN** the system ignores it and keeps waiting for a valid action rather than
  recording a grade

#### Scenario: End-of-session summary
- **WHEN** a drill session ends (all cards seen or the user quits)
- **THEN** the system prints a single summary line reporting the counts reviewed,
  got it, missed, and skipped

#### Scenario: Same command on both operating systems
- **WHEN** the user runs `learn` on Linux or on Windows
- **THEN** the same runner executes with the same behavior (single cross-platform
  implementation, no per-OS fork of the drill logic)

## ADDED Requirements

### Requirement: Runner correctness is test-covered
The system SHALL include an automated test for the drill runner that exercises the
deck parsing and the category filter without requiring interactive input, and the
test SHALL be runnable from the repository with the runner's own runtime (no extra
test framework dependency).

#### Scenario: Deck parsing includes origin and category
- **WHEN** the test loads a deck fixture with valid rows
- **THEN** each parsed card exposes its `origin` and `category` fields

#### Scenario: Malformed rows are skipped during parse
- **WHEN** the test loads a deck fixture containing a row with the wrong column count
  or a blank required field
- **THEN** that row is skipped and the remaining valid cards still load

#### Scenario: Category filter selects matching cards
- **WHEN** the test filters the deck by a category (case-insensitively)
- **THEN** only cards in that category are returned, and an unknown category returns
  no cards

### Requirement: Graceful degradation on bad input
The system SHALL not crash a drill session when its inputs are malformed. Malformed
deck rows (wrong column count or blank required fields) SHALL be skipped rather than
aborting the load, and a missing or empty deck SHALL produce a "nothing to drill"
result with no error.

#### Scenario: Malformed deck row
- **WHEN** the deck contains a row with the wrong number of columns or a blank
  required field
- **THEN** that row is skipped and the remaining valid cards still load

#### Scenario: Missing or empty deck
- **WHEN** the deck file is missing or contains no card rows
- **THEN** a session reports there is nothing to drill without erroring

### Requirement: Runner runtime is a tracked dependency
The system SHALL track the drill runner's runtime (Node) as an installed dependency
in the setup manifests so that a freshly provisioned machine has the runtime the
`learn` command requires, on both Linux and Windows.

#### Scenario: Fresh machine provisioning
- **WHEN** the setup scripts provision a new machine from the manifests
- **THEN** Node is installed (or already present and recognized) so that `learn`
  runs

## REMOVED Requirements

### Requirement: Spaced-repetition scheduling
**Reason**: The Leitner-box scheduling added friction without earning its complexity
for a small personal deck — cards you wanted to review were "not due yet". The session
now considers the whole deck every run; `learn <category>` covers focusing on a topic.
**Migration**: None. The runner no longer computes or reads next-due dates.

### Requirement: Per-machine progress persistence
**Reason**: With scheduling removed there is no box/due state to persist; grades are a
session-only tally. The hidden state file made behavior depend on invisible history.
**Migration**: Existing `progress.json` files become unused and can be deleted; the
`.gitignore` entry for them is removed.

### Requirement: Due-only shell-start nudge
**Reason**: With no "due" concept there is nothing to count at shell start, and the
nudge was easy to tune out. `learn` is now pull-only — run it when you want.
**Migration**: The nudge and its `--count` code are removed from `zsh/.zshrc` and
`pwsh/profile.ps1`; the node-guarded `learn` alias stays.
