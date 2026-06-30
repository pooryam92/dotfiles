#!/usr/bin/env bash
# Keep the installed tools current on Pop!_OS / Ubuntu — the companion to install.sh.
# (Config FILES are symlinks into this repo, so `git pull` already updates those; this
# only touches the binaries install.sh installs.)
#
# install.sh is install-once (every step is guarded "if command -v X; skip"), so
# re-running it never upgrades anything. This script forces each tool to its latest
# release — and, unlike a bare installer, shows *what* changes to *which* version and
# links the release notes so you can spot breaking changes. Windows uses update.ps1.
#
# Managed tools + their version sources / changelogs live in tools.tsv; the shared
# helpers and upgrade actions live in lib.sh.
#
#   ./setup/update.sh            preview updates, confirm, upgrade, then summarise
#   ./setup/update.sh check      list ONLY what's behind (exit 1 if any); no changes
#   ./setup/update.sh versions   full installed-vs-latest table; no changes, no sudo
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
MODE="${1:-update}"        # update | check | versions

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
    info 'Upgrade with:  ./setup/update.sh'
  fi
  return "$any"
}

cmd_versions() {
  print_status_table
  echo
  info '⚠ = major (or 0.x minor) jump — most likely to carry breaking changes.'
  info 'Upgrade everything to LATEST with:  ./setup/update.sh'
}

do_upgrades() {
  # apt-managed (includes WezTerm via its Fury repo). --only-upgrade so we don't
  # newly pull anything install.sh chose to leave out.
  info "Upgrading apt packages (needs sudo)…"
  sudo apt-get update -y
  sudo apt-get install --only-upgrade -y "${BASE_APT[@]}" wezterm

  # Starship / zoxide / Neovim / font — official installers / tarball always fetch
  # latest and overwrite (the fetch_* helpers in lib.sh, shared with install.sh).
  info "Upgrading Starship…"; fetch_starship
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

# ---------------------------------------------------------------------------
case "$MODE" in
  update)   cmd_update ;;
  check)    cmd_check ;;
  versions) cmd_versions ;;
  *) echo "usage: update.sh [update|check|versions]" >&2; exit 2 ;;
esac
