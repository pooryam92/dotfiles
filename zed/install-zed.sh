#!/usr/bin/env bash
# Installs Zed (opt-in; not part of install.sh, which links the config). Self-updates.
set -euo pipefail

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
