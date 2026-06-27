# Backlog

Small, deferred tasks. One line each — link details where useful.

- [ ] **Drop the WezTerm window rule once on WezTerm nightly.** The
  `default-column-width {}` rule in `niri/config.kdl` works around a WezTerm
  initial-configure bug that only shows up on stable (`20240203`). It's fixed in
  WezTerm nightly. After upgrading: remove the rule, launch WezTerm under niri,
  confirm it appears and resizes (also re-check the `prefer-no-csd` tiled-size
  bug). See [docs/niri.md](docs/niri.md).
