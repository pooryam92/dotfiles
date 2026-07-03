# Backlog

Small, deferred tasks. One line each — link details where useful.

- [ ] **Add `fd` and point fzf at it.** `fd` isn't installed (lib.sh line ~225
  intentionally skips it + ripgrep since the nvim config is colorscheme-only).
  Adding it would mostly help the *shell*: set `FZF_DEFAULT_COMMAND='fd --type f
  --hidden --exclude .git'` (+ `FZF_CTRL_T_COMMAND`) in both `zsh/.zshrc` and
  `pwsh/profile.ps1` so Ctrl+T / fzf respect `.gitignore` and run faster. Needs a
  `tools.tsv` row (`gh:sharkdp/fd` for a clean `fd` binary name; `scoop_pkg=fd`) +
  a `fetch_fd`/`install_fd` in lib.sh, and update the line-225 note. Optional
  follow-ons: `delta` (git diffs), `bat`/`eza`. (Goal #2: weigh against staying small.)

- [ ] **Drop the WezTerm window rule once on WezTerm nightly.** The
  `default-column-width {}` rule in `niri/config.kdl` works around a WezTerm
  initial-configure bug that only shows up on stable (`20240203`). It's fixed in
  WezTerm nightly. After upgrading: remove the rule, launch WezTerm under niri,
  confirm it appears and resizes (also re-check the `prefer-no-csd` tiled-size
  bug). See [docs/niri.md](docs/niri.md).
