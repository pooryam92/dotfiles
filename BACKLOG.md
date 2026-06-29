# Backlog

Small, deferred tasks. One line each — link details where useful.

- [ ] **Fix the phantom WezTerm "Ctrl+p/t/n/s modes" references.** The
  `wezterm.lua` is flat direct `Alt+` chords with no `key_tables`/leader (see its
  line 45 comment), but `zsh/.zshrc` (the multiplexing comment near the bottom) and
  `README.md` still describe Zellij-style `Ctrl+p`/`Ctrl+t` modes that no longer
  exist. Update both to match the actual config (Goal #3: keep docs in sync).

- [ ] **Drop the WezTerm window rule once on WezTerm nightly.** The
  `default-column-width {}` rule in `niri/config.kdl` works around a WezTerm
  initial-configure bug that only shows up on stable (`20240203`). It's fixed in
  WezTerm nightly. After upgrading: remove the rule, launch WezTerm under niri,
  confirm it appears and resizes (also re-check the `prefer-no-csd` tiled-size
  bug). See [docs/niri.md](docs/niri.md).
