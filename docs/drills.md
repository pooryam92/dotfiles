# Drills (`learn`)

A tiny **flashcard deck** for the tools in this repo. The problem it solves is
*unknown unknowns* — features you'd use if only you knew they existed. A passive
"tip of the day" can't help there (you can't act slowly on a feature you've never
heard of), and the previous tip-feed was removed for being easy to tune out. So
instead of telling you a fact, a drill **challenges** you. Each card clears the screen
and lands like a flashcard, with a progress meter and a running tally:

```
🎴  WezTerm · custom    ███░░░░░░░░░░░  3/14

  Reorder the panes in the current tab without closing any. How?

  ↳ press any key to reveal · q to quit …

  ✓ Alt+Shift+[ rotates counter-clockwise, Alt+Shift+] clockwise (RotatePanes).

  g got it   m missed   s skip   q quit      ✓2 ✗0 ⤼0
```

You read the task, go try it in the real tool, then reveal the answer and grade
yourself. Active recall is what makes it stick. Colour (task, answer, grade keys, the
meter) is used only in an interactive terminal — piping `learn` or setting `NO_COLOR`
falls back to plain text, and the same codes render on both Windows Terminal and
WezTerm.

There is **no scheduling** — every card is fair game every session, and you pull a
session whenever you want. (An earlier version used spaced-repetition due dates; they
added friction without earning it for a small personal deck, so they were removed.)

- **Runner:** `drills/drill.js` — one cross-platform Node script (Node is already
  in the stack via Claude Code, so no new runtime — same reasoning as
  `claude/statusline.js`).
- **Deck:** `drills/deck.tsv` — curated, versioned, hand-editable.
- **Runtime:** Node, tracked in `setup/tools.tsv` so a fresh machine installs it.

---

## Using it

Run a session from either shell:

```sh
learn            # pick a tool from an interactive menu, then drill it
learn niri       # skip the menu, drill the niri cards directly
```

Plain `learn` opens an **arrow-key category menu** instead of marching through the
whole deck. Categories are the tools themselves, so each row is one tool with its
card count, plus an *All categories* entry on top:

```
🎴 Pick a category to drill — ↑/↓ move · Enter start · q quit
  ▸ All categories  (72)
    niri            (22)
    wezterm         (14)
    zsh             (13)
    …
```

`↑`/`↓` (or `k`/`j`) move the cursor, **Enter** starts the highlighted tool, and
`q`/`Esc` cancels without drilling. This is what keeps the tool usable as the deck
grows: you drill one tool at a time rather than skimming everything. The menu only
appears in an interactive terminal — piping `learn` (or passing a `<category>`)
skips it, so scripted use still runs against the whole deck.

`learn` is a function/alias defined in `zsh/.zshrc` and `pwsh/profile.ps1` (guarded
on Node — if Node isn't installed the command is silently absent). For each card:

1. The task is shown — go attempt it in the actual tool.
2. Press any key to **reveal** the answer (`q` quits).
3. Grade yourself: **`g`** got it · **`m`** missed · **`s`** skip (don't grade it) ·
   **`q`** quit. Arrow keys and other stray keys at the grade prompt are ignored. The
   tally on the right (`✓ ✗ ⤼`) updates as you go.

Cards are **shuffled** each interactive session, so order never becomes a memory
crutch — you recall the answer, not "the third card." (Piped/non-interactive runs keep
deck order so scripted output stays stable.)

At the end it prints one summary line — how many you reviewed, got, missed, and
skipped:

```
🎴 Reviewed 12 (9 got it · 3 missed · 1 skipped) of 14.
```

Nothing is saved between sessions; the grade is just that session's tally.

### Filtering by category

Two ways to narrow a session to one topic:

- **The menu** — run plain `learn` and pick a tool (see above). Best when you don't
  remember the exact tool names.
- **By name** — `learn <tool>` jumps straight in, exact match, case-insensitive
  (e.g. `learn wezterm`, `learn zsh`, `learn niri`). An unknown name reports that
  nothing matches rather than falling back to the whole deck.

---

## Adding cards

The deck is a TSV with six tab-separated columns — add one row, no code changes:

```
id	tool	task	reveal	origin	category
```

- **`id`** — unique, kebab-case (e.g. `zsh-fzf-history`).
- **`tool`** — the owning tool, shown in the card header.
- **`task`** — phrased as a "can you do X?" challenge, not a statement.
- **`reveal`** — the answer (keybinding/command), ideally with a one-line why.
- **`origin`** — **`custom`** if the feature is configured in this repo's dotfiles
  (it won't exist on a vanilla install — e.g. a WezTerm keybind in `wezterm.lua`, a
  zsh `setopt`, a niri/keyd binding); **`builtin`** if it's a tool default that works
  out of the box (e.g. zoxide's `z`). The rule of thumb: *did I set this up, or does
  the tool do it by default?*
- **`category`** — the owning tool in lowercase (e.g. `wezterm`, `zsh`, `zoxide`,
  `starship`, `keyd`, `niri`) — the same tool as the `tool` column, just lowercased.
  It's the axis `learn <tool>` filters on and the category menu groups by, so a new
  card for an existing tool reuses that tool's slug rather than inventing a new one.

A row missing any column (or with a blank field) is skipped at load time, so a
half-filled card just won't appear — check the card count if one goes missing.

Keep reveals grounded in the actual config (`wezterm/wezterm.lua`, `zsh/.zshrc`,
`starship/starship.toml`, `niri/config.kdl`, `keyd/default.conf`, …) and re-check
them when those configs change — a stale answer is worse than no card. The deck
seeds the daily drivers first (WezTerm, zsh, Starship, zoxide) and grows by hand
from there.

---

## Tests

`drills/drill.test.js` covers deck parsing (including the `origin`/`category`
columns and skipping malformed rows) and the category filter. No framework — run it
with the runner's own runtime:

```sh
node --test drills/
```
