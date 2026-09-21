#!/usr/bin/env bash
# Installs VS Code (opt-in; not part of install.sh, which links the config).
# Upgrades come with apt, from Microsoft's repo added below.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/setup/lib.sh"

# --- VS Code itself ---------------------------------------------------------
if command -v code >/dev/null; then
  info "VS Code already installed ($(code --version 2>/dev/null | head -1)); upgrades come via apt."
else
  info "Installing VS Code from Microsoft's apt repo (needs sudo)…"
  keep_sudo_fresh

  # Write the key through a temp file: sudo can't always read the caller's
  # /dev/fd entries from a process substitution.
  key="$(mktemp)"
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$key" \
    || die "could not fetch/dearmor Microsoft's signing key"
  sudo install -D -o root -g root -m 644 "$key" /usr/share/keyrings/microsoft.gpg
  rm -f "$key"

  # signed-by pins the repo to that key.
  echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

  sudo apt-get update -y
  sudo apt-get install -y code || die "VS Code install failed; see https://code.visualstudio.com/docs/setup/linux"
  info "Installed $(code --version 2>/dev/null | head -1)"
fi

# --- Extensions -------------------------------------------------------------
# Which extensions to install is data: vscode/extensions.txt, shared with
# install-vscode.ps1. --force makes --install-extension idempotent, and
# `|| [ -n "$line" ]` catches a final line with no trailing newline.
while read -r line || [ -n "$line" ]; do
  ext="${line%%#*}"                      # strip trailing comment (ids have no #)
  ext="$(printf '%s' "$ext" | tr -d '[:space:]')"
  [ -z "$ext" ] && continue
  info "Installing extension $ext…"
  # </dev/null so `code` cannot swallow the loop's stdin.
  code --install-extension "$ext" --force </dev/null \
    || warn "could not install $ext; install it from the Extensions view"
done < "$DOTFILES/vscode/extensions.txt"

info "Config is linked by install.sh (vscode/settings.json, vscode/keybindings.json). See vscode/README.md."
info "Note: .md files open RENDERED by default — press Ctrl+Shift+V to edit the source."
