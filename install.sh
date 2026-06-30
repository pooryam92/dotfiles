#!/usr/bin/env bash
# Dotfiles installer for Pop!_OS / Ubuntu (WezTerm + zsh + Starship).
# Idempotent: safe to re-run. Existing files are backed up before linking.
# Windows uses install.ps1 instead. The managed tools live in setup/tools.tsv and the
# config-link targets in setup/links.tsv; the shared actions/helpers are in setup/lib.sh.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup/lib.sh"
mkdir -p "$BIN" "$HOME/.config"

# Authenticate sudo up front and keep it alive — the keyd source build later can
# outlast sudo's timeout and would otherwise surprise-prompt mid-install.
keep_sudo_fresh

# --- system packages -------------------------------------------------------
info "Installing apt packages (needs sudo)…"
sudo apt-get update -y
sudo apt-get install -y "${BASE_APT[@]}"

# --- tools (install-once; each guards itself) ------------------------------
# Driven by the manifest (setup/tools.tsv) in order — INSTALL_TOOLS is every tool for
# this platform. Each install_<name> in lib.sh is that tool's install-once guard; a row
# with no matching action is a manifest/lib mismatch, so fail loudly rather than skip it.
for t in "${INSTALL_TOOLS[@]}"; do
  declare -F "install_$t" >/dev/null || die "tools.tsv lists '$t' but setup/lib.sh has no install_$t"
  "install_$t"
done

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
