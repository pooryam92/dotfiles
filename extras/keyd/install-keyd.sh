#!/usr/bin/env bash
# Installs keyd (system-level key remapper) and pushes extras/keyd/default.conf live.
# Linux-only and opt-in: the niri installer runs this (Right Alt → Super is niri's Mod);
# run it directly for CapsLock-as-Esc/Ctrl on stock COSMIC. See extras/keyd/README.md.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/setup/lib.sh"

# keyd remaps at the evdev layer, so it works under any compositor, X11 and the TTY.
# Not packaged for Pop!_OS 24.04, so build from source; install-once, never rebuilt.
if command -v keyd >/dev/null; then
  info "keyd already installed ($(keyd --version 2>/dev/null | head -1))"
else
  info "Installing keyd (key remapper; needs sudo)…"
  keep_sudo_fresh
  sudo apt-get install -y build-essential
  src="${SRC_DIR:-$HOME/src}/keyd"
  if [ -d "$src/.git" ]; then
    git -C "$src" pull --ff-only || warn "could not update keyd; building current checkout"
  else
    git clone https://github.com/rvaiya/keyd "$src"
  fi
  ( cd "$src" && make && sudo make install )
  sudo systemctl enable --now keyd
fi

# /etc is root-owned and keyd starts at boot (before $HOME may be mounted), so the
# config is copied, not symlinked. Re-run this script after editing default.conf.
info "Installing keyd config…"
sudo install -Dm644 "$DOTFILES/extras/keyd/default.conf" /etc/keyd/default.conf
sudo keyd reload 2>/dev/null || warn "keyd reload failed; run 'sudo keyd reload' once the service is up"
info "Done. CapsLock = Esc (tap) / Ctrl (hold); Right Alt = Super."
