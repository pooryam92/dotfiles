#!/usr/bin/env bash
# Install VS Code — the GUI editor — Pop!_OS / Ubuntu, OPT-IN.
#
# This is NOT part of the main install.sh. install.sh manages the terminal/CLI
# stack (WezTerm, zsh, zoxide, fd/rg/bat, Neovim, Claude Code, the Nerd Font…);
# VS Code is a GUI app, so it installs on its own — the same way
# zed/install-zed.sh and niri/install-cosmic-niri.sh do. VS Code's *config* files
# are still symlinked by install.sh's do_links (vscode/settings.json,
# vscode/keybindings.json via links.tsv); only the install lives here.
#
# UPDATES: unlike Zed (which self-updates), the Linux build is apt-managed via
# Microsoft's repo added below, so VS Code upgrades with a normal
# `sudo apt-get upgrade`. `install.sh update` deliberately does NOT touch it —
# that command scopes itself to BASE_APT, the packages install.sh owns.
#
# Windows counterpart: vscode/install-vscode.ps1 (winget — and see that file for
# why it isn't scoop). See vscode/README.md.
set -euo pipefail

# Reuse install.sh's shared helpers — info/warn/die/keep_sudo_fresh. lib.sh is the
# repo's shared shell-helpers module; sourcing it keeps that logic in ONE place
# (same pattern as the zed and niri installers) instead of re-implementing it here.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/setup/lib.sh"

# --- VS Code itself ---------------------------------------------------------
if command -v code >/dev/null; then
  info "VS Code already installed ($(code --version 2>/dev/null | head -1)); upgrades come via apt."
else
  info "Installing VS Code from Microsoft's apt repo (needs sudo)…"
  keep_sudo_fresh

  # Microsoft's signing key, dearmored into its own keyring. Write it via a temp
  # file rather than a process substitution: sudo can't always read the caller's
  # /dev/fd entries. mktemp gives an unpredictable, mode-600 path (same reasoning
  # as the fetch_* helpers in lib.sh).
  key="$(mktemp)"
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$key" \
    || die "could not fetch/dearmor Microsoft's signing key"
  sudo install -D -o root -g root -m 644 "$key" /usr/share/keyrings/microsoft.gpg
  rm -f "$key"

  # signed-by pins the repo to that key only — never trusted repo-wide.
  echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

  sudo apt-get update -y
  sudo apt-get install -y code || die "VS Code install failed; see https://code.visualstudio.com/docs/setup/linux"
  info "Installed $(code --version 2>/dev/null | head -1)"
fi

# --- Extensions -------------------------------------------------------------
# The things settings.json can't provide on its own. WHICH extensions is data —
# vscode/extensions.txt, read by this script AND by install-vscode.ps1, so the two
# OSes can't drift (goal #3). --force makes this idempotent (it no-ops when the
# extension is already present and current) instead of erroring on a re-run.
# `|| [ -n "$line" ]` catches a final line with no trailing newline: read returns
# false there but still fills $line, so a plain `while read` would drop it.
while read -r line || [ -n "$line" ]; do
  ext="${line%%#*}"                      # strip trailing comment (ids have no #)
  ext="$(printf '%s' "$ext" | tr -d '[:space:]')"
  [ -z "$ext" ] && continue              # blank / comment-only line
  info "Installing extension $ext…"
  # </dev/null so `code` can't swallow the loop's stdin and eat the rest of the list.
  code --install-extension "$ext" --force </dev/null \
    || warn "could not install $ext; install it from the Extensions view"
done < "$DOTFILES/vscode/extensions.txt"

info "Config is linked by install.sh (vscode/settings.json, vscode/keybindings.json). See vscode/README.md."
info "Note: .md files open RENDERED by default — press Ctrl+Shift+V to edit the source."
