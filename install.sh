#!/usr/bin/env bash
# Dotfiles front door for Pop!_OS / Ubuntu — installs AND updates the terminal/CLI
# stack (WezTerm + zsh + Neovim + zoxide + fd/rg/bat + Claude Code + font + keyd).
# Windows uses install.ps1 instead. The managed tools live in setup/tools.tsv, the
# config-link targets in setup/links.tsv, and the shared actions/helpers in setup/lib.sh.
#
#   ./install.sh              install everything (default; idempotent, safe to re-run)
#   ./install.sh update       preview updates, confirm, upgrade, then summarise
#   ./install.sh check        list ONLY what's behind (exit 1 if any); no changes
#   ./install.sh versions     full installed-vs-latest table; no changes, no sudo
#
# Install is install-once (every step is guarded "if command -v X; skip"), so re-running
# `install` never upgrades anything — that's what `update` is for: it forces each tool to
# its latest release and shows *what* moves to *which* version with release-notes links.
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

  # --- tools (install-once; each guards itself) ----------------------------
  # Driven by the manifest (setup/tools.tsv) in order — INSTALL_TOOLS is every tool for
  # this platform. Each install_<name> in lib.sh is that tool's install-once guard; a row
  # with no matching action is a manifest/lib mismatch, so fail loudly rather than skip it.
  for t in "${INSTALL_TOOLS[@]}"; do
    declare -F "install_$t" >/dev/null || die "tools.tsv lists '$t' but setup/lib.sh has no install_$t"
    "install_$t"
  done

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

# Installed-vs-latest table with a breaking-change flag + release-notes link for
# anything behind. Shared by `versions` and the pre-update preview.
print_status_table() {
  printf '%-9s %-24s %-24s %s\n' TOOL INSTALLED 'LATEST/AVAILABLE' NOTES
  local t old new note
  for t in "${TOOLS[@]}"; do
    old="$(norm "$(installed_version "$t")")"
    new="$(norm "$(latest_version  "$t")")"
    if   [ -z "$new" ];          then note='(could not check — offline?)'
    elif [ "$old" = present ];   then note='installed (version not detectable)'
    elif is_behind "$t" "$old" "$new"; then note="$(bump_flag "$old" "$new")  → $(changelog_url "$t")"
    else note='up to date'
    fi
    printf '%-9s %-24s %-24s %s\n' "$t" "${old:-—}" "${new:-—}" "$note"
  done
}

# Only the tools that are behind — the "what needs updating?" view. Exits 1 when
# something is outdated (handy in scripts / prompts), 0 when all current.
cmd_check() {
  local t old new any=0
  for t in "${TOOLS[@]}"; do
    old="$(norm "$(installed_version "$t")")"
    new="$(norm "$(latest_version  "$t")")"
    if is_behind "$t" "$old" "$new"; then
      printf '%s %-9s %-12s → %-12s %s\n' "$(bump_flag "$old" "$new")" \
        "$t" "${old:-—}" "$new" "$(changelog_url "$t")"
      any=1
    fi
  done
  if [ "$any" = 0 ]; then
    info "Everything is up to date. ✓"
  else
    echo
    info '⚠ = major (or 0.x minor) jump — skim its release notes for breaking changes.'
    info 'Upgrade with:  ./install.sh update'
  fi
  return "$any"
}

cmd_versions() {
  print_status_table
  echo
  info '⚠ = major (or 0.x minor) jump — most likely to carry breaking changes.'
  info 'Upgrade everything to LATEST with:  ./install.sh update'
}

do_upgrades() {
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
}

cmd_update() {
  # 1. Preview: what's behind, by how much, and where to read the release notes.
  info "Checking what's available before changing anything…"
  echo
  print_status_table
  echo
  info '⚠ = major (or 0.x minor) jump — skim its release notes for breaking changes.'

  # 2. Let you bail after seeing the preview (only when run interactively).
  if [ -t 0 ]; then
    printf '\nProceed with the upgrade? [Y/n] '
    read -r ans
    case "$ans" in [Nn]*) info "Aborted — nothing changed."; exit 0 ;; esac
  fi

  # 3. Snapshot, upgrade, then report exactly what moved.
  declare -A OLD
  local t
  for t in "${TOOLS[@]}"; do OLD[$t]="$(norm "$(installed_version "$t")")"; done

  do_upgrades

  echo
  info "Update summary — what actually changed:"
  local new changed=0
  for t in "${TOOLS[@]}"; do
    new="$(norm "$(installed_version "$t")")"
    if [ "${OLD[$t]}" != "$new" ]; then
      printf '   %-9s %s → %s   %s\n' "$t" "${OLD[$t]:-—}" "${new:-—}" "$(changelog_url "$t")"
      changed=1
    fi
  done
  [ "$changed" = 0 ] && info "   Nothing moved — everything was already current."
  echo
  info "Restart your shell (exec zsh) to pick up the new versions."
}

usage() {
  cat <<'EOF'
usage: ./install.sh [command]
  install     install the terminal/CLI stack (default; idempotent, safe to re-run)
  update      preview → confirm → upgrade tools to latest → summary of what moved
  check       list ONLY what's behind (exit 1 if any); no changes
  versions    full installed-vs-latest table; no changes, no sudo
EOF
}

# ---------------------------------------------------------------------------
case "${1:-install}" in
  install)  cmd_install ;;
  update)   cmd_update ;;
  check)    cmd_check ;;
  versions) cmd_versions ;;
  help|-h|--help) usage ;;
  *) echo "unknown command: $1" >&2; echo >&2; usage >&2; exit 2 ;;
esac
