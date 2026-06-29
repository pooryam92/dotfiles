# Drills (`learn`)

A tiny **spaced-repetition deck** for the tools in this repo. The problem it
solves is *unknown unknowns* — features you'd use if only you knew they existed.
A passive "tip of the day" can't help there (you can't act slowly on a feature
you've never heard of), and the previous tip-feed was removed for being easy to
tune out. So instead of telling you a fact, a drill **challenges** you:

```
── 3/14  [WezTerm]
   Reorder the panes in the current tab without closing any. How?
   ↳ press any key to reveal · q to quit …
   ✓ Alt+Shift+[ rotates counter-clockwise, Alt+Shift+] clockwise (RotatePanes).
   got it? (g = got it · m = missed · q = quit) …
```

You read the task, go try it in the real tool, then reveal the answer and grade
yourself. Active recall + spaced repetition makes it stick.

- **Runner:** `drills/drill.js` — one cross-platform Node script (Node is already
  in the stack via Claude Code, so no new runtime — same reasoning as
  `claude/statusline.js`).
- **Deck:** `drills/deck.tsv` — curated, versioned, hand-editable.

---

## Using it

Run a session from either shell:

```sh
learn
```

`learn` is a function/alias defined in `zsh/.zshrc` and `pwsh/profile.ps1`. It
shows only the cards that are **due** (never-seen cards count as due). For each:

1. The task is shown — go attempt it in the actual tool.
2. Press any key to **reveal** the answer (`q` quits and saves).
3. Grade yourself: **`g`** got it · **`m`** missed.

When nothing is due, it says so rather than re-drilling what you've mastered.

### The shell-start nudge

On a new shell, **only when cards are due**, one line prints and nothing else:

```
🎴 4 drills due — run learn
```

Silent otherwise. It's a content-free pointer (a count, never an answer) that
nudges you to *pull* a session — the opposite of a tip shoved at you mid-work.
If Node isn't installed, the nudge and the `learn` command are skipped silently.

---

## Scheduling (Leitner boxes)

Each card sits in a box; the box sets how long until it's due again:

| Box | Next due in |
| --- | ----------- |
| 1   | 1 day       |
| 2   | 3 days      |
| 3   | 7 days      |
| 4   | 21 days     |
| 5   | 60 days     |

- **Got it** → advance one box (capped at 5) and push the due date out by that
  box's interval.
- **Missed** → reset to box 1 and become due again immediately, so it resurfaces
  next session.

It's deliberately not a full SM-2/Anki engine — a handful of boxes is plenty for
a personal deck of dozens of cards.

---

## Where progress lives

Your boxes and due dates are per-machine and **never committed** (progress is
personal and would only create cross-machine merge noise — same reasoning as
`.zsh_history`). The state file is a small `progress.json` under the OS state dir:

- **Linux/macOS:** `$XDG_STATE_HOME/dotfiles-drills/progress.json`
  (default `~/.local/state/dotfiles-drills/progress.json`)
- **Windows:** `%LOCALAPPDATA%\dotfiles-drills\progress.json`

It's gitignored defensively (`drills/progress.json`) in case it's ever generated
inside the repo. Delete the file to reset all progress.

---

## Adding cards

The deck is a TSV with four tab-separated columns — add one row, no code changes:

```
id	tool	task	reveal
```

- **`id`** — unique, kebab-case (e.g. `zsh-fzf-history`); it's the key in the
  progress file, so don't rename it casually or you'll reset that card.
- **`tool`** — the owning tool, shown in brackets during the drill.
- **`task`** — phrased as a "can you do X?" challenge, not a statement.
- **`reveal`** — the answer (keybinding/command), ideally with a one-line why.

Keep reveals grounded in the actual config (`wezterm/wezterm.lua`,
`zsh/.zshrc`, `starship/starship.toml`, …) and re-check them when those configs
change — a stale answer is worse than no card. The deck seeds the daily drivers
first (WezTerm, zsh, Starship, zoxide) and grows by hand from there.
