# Backlog

Small, deferred tasks. One line each — link details where useful.

- [x] **CLI batch 1: `fd` + `ripgrep` + `bat`, wired into fzf on both OSes.**
  Done — apt/scoop rows in `tools.tsv`, fzf wiring in `zsh/.zshrc`, hand-rolled
  `Ctrl+T`/`Alt+C` PSReadLine handlers in `pwsh/profile.ps1`, guide in
  [docs/fzf.md](docs/fzf.md). Still to do: spend a few days building the muscle
  memory — `Ctrl+R` history, `Ctrl+T` files, `Alt+C` cd, `z`/`zi`, `rg <pattern>`.

- [ ] **CLI batch 2: shared gitconfig + `delta`.** Add `git/gitconfig` (aliases,
  pull/rebase/push defaults, zdiff3 conflicts) linked to `~/.gitconfig` on both
  OSes. Identity must stay per-person: no user.name/email in the repo — include
  `~/.gitconfig.local` LAST (last value wins) and have the installers promote an
  existing real `~/.gitconfig` to `.local` so other users of this repo never lose
  their identity. Then set `delta` as git's pager (tools.tsv row
  `gh:dandavison/delta`; scoop `delta`). Deferred 2026-07-04 — decided to land
  the fzf/fd batch first.

- [ ] **Maybe later: `lazygit`.** Keyboard-driven git TUI (stage hunks, browse
  history, rebase with single keys). Biggest workflow upgrade of the bunch but
  also the most to learn — try it only after the fzf keys and git aliases have
  settled.

- Considered, skipped for now (goal #2 — no real itch yet): `eza` (prettier `ls`
  — cosmetic; the `ls --color` aliases are fine), `atuin` (synced shell history —
  daemon + sync account is too heavy; fzf `Ctrl+R` first), `jq` (JSON processor —
  only once APIs/JSON come up regularly).

- [ ] **Try `prefer-no-csd` in `niri/config.kdl` now that WezTerm is on nightly.**
  Stable WezTerm had a tiled-size bug with it (why it was left off). Nightly may
  fix it: enable, launch WezTerm under niri, check windows still size correctly —
  revert if not. Cosmetic win: no client-side title bars.
