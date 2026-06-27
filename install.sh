#!/usr/bin/env bash
# Dotfiles installer for Pop!_OS / Ubuntu (WezTerm + zsh + Starship).
# Idempotent: safe to re-run. Existing files are backed up before linking.
# Windows uses install.ps1 instead. The managed tools live in setup/tools.tsv and the
# config-link targets in setup/links.tsv; the shared actions/helpers are in setup/lib.sh.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup/lib.sh"
mkdir -p "$BIN" "$HOME/.config"

# --- system packages -------------------------------------------------------
info "Installing apt packages (needs sudo)…"
sudo apt-get update -y
sudo apt-get install -y "${BASE_APT[@]}"

# --- tools (install-once; each guards itself) ------------------------------
install_wezterm
install_starship
install_zoxide
install_nvim
install_keyd
install_zed
install_claude
install_font

# --- config links ----------------------------------------------------------
do_links

# --- default shell ---------------------------------------------------------
ZSH_PATH="$(command -v zsh)"
grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
  info "Setting default shell to zsh (may prompt for password)…"
  chsh -s "$ZSH_PATH" || warn "chsh failed; run: chsh -s $ZSH_PATH"
fi

info "Done. Open WezTerm (or run 'exec zsh') to start using the new setup."
