## ADDED Requirements

### Requirement: Curated drill deck
The system SHALL provide a versioned, curated deck of drills stored in the repo,
where each drill describes one feature of one tool as a task to perform and the
answer to reveal. The deck SHALL be a TSV with the columns `id`, `tool`, `task`,
and `reveal`, and SHALL seed the daily-driver tools (WezTerm, zsh, Starship,
zoxide) first.

#### Scenario: Deck provides task-and-reveal challenges
- **WHEN** a maintainer opens the deck file
- **THEN** each line defines a unique `id`, the owning `tool`, a `task` phrased as a
  "can you do X?" challenge, and the `reveal` answer (e.g. the keybinding or command)

#### Scenario: Deck is hand-editable and grows over time
- **WHEN** a maintainer adds a feature to learn
- **THEN** they can add one TSV line without touching the runner code

### Requirement: Active drill session
The system SHALL provide a `learn` command that runs a drill session: for each card
chosen for the session it SHALL show the task, wait for the user to attempt it,
reveal the answer only on an explicit keypress, and then record the user's
self-graded result (got it / missed). The command SHALL be invokable from both the
Linux (zsh) and Windows (PowerShell) shells.

#### Scenario: Running a drill session
- **WHEN** the user runs `learn`
- **THEN** the system shows a task, waits, reveals the answer on a keypress, and
  prompts the user to self-grade got it / missed

#### Scenario: Nothing is due
- **WHEN** the user runs `learn` and no cards are due
- **THEN** the system reports that there is nothing to review rather than forcing
  already-mastered cards

#### Scenario: Same command on both operating systems
- **WHEN** the user runs `learn` on Linux or on Windows
- **THEN** the same runner executes with the same behavior (single cross-platform
  implementation, no per-OS fork of the drill logic)

### Requirement: Spaced-repetition scheduling
The system SHALL schedule cards with a Leitner-box algorithm: a card graded "got it"
SHALL advance one box and have its next-due date pushed further out, and a card
graded "missed" SHALL reset to the first box and become due again soon. Sessions
SHALL prioritize cards that are due (including never-seen cards) and SHALL NOT
present cards that are not yet due.

#### Scenario: Correct answer lengthens the interval
- **WHEN** the user grades a card "got it"
- **THEN** the card advances a box and its next-due date moves further into the
  future

#### Scenario: Missed answer resets the card
- **WHEN** the user grades a card "missed"
- **THEN** the card returns to the first box and becomes due again soon

#### Scenario: Only due cards are presented
- **WHEN** a drill session selects cards
- **THEN** it includes never-seen and due cards and excludes cards whose next-due
  date has not arrived

### Requirement: Per-machine progress persistence
The system SHALL persist each card's box and next-due date in a per-machine state
file located outside the git repository, under the OS state directory, and this
file SHALL NOT be committed.

#### Scenario: Progress survives across sessions
- **WHEN** the user completes a drill session and later runs `learn` again
- **THEN** the previously updated boxes and due dates are honored

#### Scenario: Progress is not committed
- **WHEN** the repository status is checked
- **THEN** the progress state file is ignored by git

### Requirement: Due-only shell-start nudge
The system SHALL print a single concise line at shell start **only when** one or
more cards are due, stating how many drills are due and how to start them, and SHALL
print nothing when no cards are due. The nudge SHALL be present in both the zsh and
PowerShell startup configs and SHALL degrade silently when the runner's runtime is
unavailable.

#### Scenario: Cards are due at shell start
- **WHEN** a new shell starts and at least one card is due
- **THEN** a single line (a count plus how to run `learn`) is printed, with no card
  content

#### Scenario: Nothing due at shell start
- **WHEN** a new shell starts and no cards are due
- **THEN** no drill output is printed

#### Scenario: Runtime missing
- **WHEN** a new shell starts and the runner's runtime (Node) is unavailable
- **THEN** the nudge is silently skipped and no error is shown
