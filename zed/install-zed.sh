#!/usr/bin/env bash
# Install Zed — the GUI editor — Pop!_OS / Ubuntu, OPT-IN.
#
# This is NOT part of the main install.sh. install.sh manages the terminal/CLI
# stack (WezTerm, zsh, zoxide, fd/rg/bat, Neovim, Claude Code, the Nerd Font…);
# Zed is a GUI app, so it installs on its own — the same way
# niri/install-cosmic-niri.sh does. Zed's *config* files are still symlinked by
# install.sh's do_links (zed/settings.json, zed/keymap.json via links.tsv); only
# the binary install lives here.
#
# The official installer drops Zed under ~/.local and it self-updates afterwards,
# so there's no separate update path — `install.sh update` never touches it. Re-running this
# is safe: it skips the install when zed is already on PATH.
#
# Windows counterpart: zed/install-zed.ps1 (scoop). See zed/README.md.
set -euo pipefail

# Reuse install.sh's shared helpers — info/warn/die. lib.sh is the repo's shared
# shell-helpers module; sourcing it keeps that logic in ONE place (same pattern as
# the niri installer) instead of re-implementing it here.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/setup/lib.sh"

if command -v zed >/dev/null; then
  info "zed already installed ($(zed --version 2>/dev/null | head -1)); it self-updates."
else
  info "Installing Zed…"
  curl -fsSL https://zed.dev/install.sh | sh \
    || die "Zed install failed; see https://zed.dev/docs/linux"
  info "Installed $(zed --version 2>/dev/null | head -1)"
fi

info "Config is linked by install.sh (zed/settings.json, zed/keymap.json). See zed/README.md."
