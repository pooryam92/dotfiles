"""keymap — your personal shell-usage heatmap (and data for an agent).

A *sense layer* for the terminal: it reads your shell history and turns it into a
picture of what you actually lean on — most-run commands, busy subcommands, and
the aliases you defined but never use. Split by concern:

  history.py  find the shell-history file and parse it into (ts, command) events
  redact.py   the privacy layer — mask secrets BEFORE anything is counted/shown
  parse.py    tokenize a command into (program, subcommand), seeing through sudo
  aliases.py  read the user's aliases / functions from the shell config
  profile.py  crunch events + aliases into the structured profile both faces use
  content.py  render that profile as framework-neutral `tui.Doc`s
  cli.py      argument handling, --json, plain output, launching the TUI
  keymap.py   the thin entry the installer symlinks to ~/.config/keymap.py

The intelligence isn't in here. keymap only *measures*; deciding what to change
(a new alias, a zoxide nudge, a cheat entry) is the agent's job — see the
`/keymap` slash command. That keeps this tool dumb, honest, and free of baked-in
opinions that rot.
"""

__version__ = "1.0.0"
