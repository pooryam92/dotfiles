#!/usr/bin/env bash
# Dotfiles front door for Pop!_OS / Ubuntu — installs and updates the terminal + editor stack.
# install is install-once (every step is guarded); update is what upgrades.
#
#   ./install.sh              install everything (default)
#   ./install.sh update       force every managed tool to its latest release
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup/lib.sh"

# --- install ----------------------------------------------------------------
cmd_install() {
  mkdir -p "$BIN" "$HOME/.config"

  keep_sudo_fresh

  # --- system packages -----------------------------------------------------
  info "Installing apt packages (needs sudo)…"
  sudo apt-get update -y
  sudo apt-get install -y "${BASE_APT[@]}"

  # --- tools ---------------------------------------------------------------
  install_wezterm
  install_zoxide
  install_fd
  install_rg
  install_bat
  install_nvim
  install_font
  install_claude

  # --- GUI editors ---------------------------------------------------------
  install_zed
  install_vscode
  install_vscode_extensions

  # --- config links --------------------------------------------------------
  do_links

  # --- default shell -------------------------------------------------------
  ZSH_PATH="$(command -v zsh)"
  grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
  CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
  if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    info "Setting default shell to zsh (may prompt for password)…"
    chsh -s "$ZSH_PATH" || warn "chsh failed; run: chsh -s $ZSH_PATH"
  fi

  info "Done. Open WezTerm (or run 'exec zsh') to start using the new setup."
}

# --- update -----------------------------------------------------------------

cmd_update() {
  keep_sudo_fresh

  # --only-upgrade so update never pulls packages install left out.
  info "Upgrading apt packages (needs sudo)…"
  sudo apt-get update -y
  sudo apt-get install --only-upgrade -y "${BASE_APT[@]}" fd-find ripgrep bat
  # VS Code is apt-managed too (Microsoft's repo, added by install), but only once installed.
  if command -v code >/dev/null; then sudo apt-get install --only-upgrade -y code; fi

  info "Upgrading WezTerm…";  fetch_wezterm
  info "Upgrading zoxide…";   fetch_zoxide
  info "Upgrading Neovim…";   fetch_nvim
  info "Upgrading JetBrainsMono Nerd Font…"; fetch_font

  if command -v claude >/dev/null; then
    info "Updating Claude Code…"
    claude update || warn "claude update failed; it also self-updates on launch"
  fi

  # Zed self-updates; VS Code came through apt above. Extensions re-run so new lines in
  # vscode/extensions.txt land on every update.
  install_vscode_extensions

  info "Done. Restart your shell (exec zsh) to pick up the new versions."
}

usage() {
  cat <<'EOF'
usage: ./install.sh [command]
  install     install the terminal + editor stack (default; idempotent, safe to re-run)
  update      force every managed tool to its latest release
EOF
}

# ---------------------------------------------------------------------------
case "${1:-install}" in
  install)  cmd_install ;;
  update)   cmd_update ;;
  help|-h|--help) usage ;;
  *) echo "unknown command: $1" >&2; echo >&2; usage >&2; exit 2 ;;
esac
