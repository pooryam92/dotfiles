#!/usr/bin/env bash
# Dotfiles front door for Pop!_OS / Ubuntu — installs AND updates the terminal/CLI
# stack (WezTerm + zsh + Neovim + zoxide + fd/rg/bat + Claude Code + font + keyd).
# Windows uses install.ps1 instead. The config-link targets live in setup/links.tsv,
# and the shared actions/helpers (install_*/fetch_* per tool) in setup/lib.sh.
#
#   ./install.sh              install everything (default; idempotent, safe to re-run)
#   ./install.sh update       force every managed tool to its latest release
#
# Install is install-once (every step is guarded "if command -v X; skip"), so re-running
# `install` never upgrades anything — that's what `update` is for. There is no version
# bookkeeping: apt and the fetch_* helpers already know how to fetch latest, so update
# just re-runs them all.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup/lib.sh"

# --- install ----------------------------------------------------------------
cmd_install() {
  mkdir -p "$BIN" "$HOME/.config"

  # Authenticate sudo up front and keep it alive — the keyd source build later can
  # outlast sudo's timeout and would otherwise surprise-prompt mid-install.
  keep_sudo_fresh

  # --- system packages -----------------------------------------------------
  info "Installing apt packages (needs sudo)…"
  sudo apt-get update -y
  sudo apt-get install -y "${BASE_APT[@]}"

  # --- tools (install-once; each install_* in lib.sh guards itself) --------
  install_wezterm
  install_zoxide
  install_fd
  install_rg
  install_bat
  install_nvim
  install_font
  install_claude
  install_keyd

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
# (Config FILES are symlinks into this repo, so `git pull` already updates those; the
# commands below only touch the binaries `install` installs.)

cmd_update() {
  keep_sudo_fresh

  # apt-managed. --only-upgrade so we don't newly pull anything install chose to
  # leave out.
  info "Upgrading apt packages (needs sudo)…"
  sudo apt-get update -y
  sudo apt-get install --only-upgrade -y "${BASE_APT[@]}" fd-find ripgrep bat

  # WezTerm / zoxide / Neovim / font — installers / release downloads always fetch
  # latest and overwrite (the fetch_* helpers in lib.sh, shared with install).
  # WezTerm tracks the nightly channel — see fetch_wezterm for why.
  info "Upgrading WezTerm…";  fetch_wezterm
  info "Upgrading zoxide…";   fetch_zoxide
  info "Upgrading Neovim…";   fetch_nvim
  info "Upgrading JetBrainsMono Nerd Font…"; fetch_font

  # Claude Code — native installer, self-updating. `claude update` forces it now.
  if command -v claude >/dev/null; then
    info "Updating Claude Code…"
    claude update || warn "claude update failed; it also self-updates on launch"
  fi

  info "Done. Restart your shell (exec zsh) to pick up the new versions."
}

usage() {
  cat <<'EOF'
usage: ./install.sh [command]
  install     install the terminal/CLI stack (default; idempotent, safe to re-run)
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
