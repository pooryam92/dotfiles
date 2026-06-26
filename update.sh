#!/usr/bin/env bash
# Keep the installed TOOLS current on Pop!_OS / Ubuntu — the companion to
# install.sh. (The config FILES are symlinks into this repo, so `git pull` already
# updates those; this script only touches the binaries install.sh installs.)
#
# install.sh is install-once: every step is guarded with `if command -v X; skip`,
# so re-running it never upgrades anything. This script forces each tool to its
# latest release instead — and, unlike a bare installer, it shows you *what*
# changes to *which* version and links the release notes so you can spot breaking
# changes. Windows uses update.ps1.
#
#   ./update.sh            preview updates, confirm, upgrade, then summarise
#   ./update.sh check      list ONLY what's behind (exit 1 if any); no changes
#   ./update.sh versions   full installed-vs-latest table; no changes, no sudo
set -euo pipefail

ARCH="$(dpkg --print-architecture)"
BIN="$HOME/.local/bin"
MODE="${1:-update}"        # update | check | versions

# Every tool we manage, in display order.
TOOLS=(wezterm starship zoxide nvim zed font claude)

# Base apt packages install.sh manages — targeted so we upgrade just these, not
# the whole system. Keep in sync with install.sh.
APT_PKGS=(zsh git curl unzip ca-certificates fontconfig wl-clipboard fzf
          zsh-autosuggestions zsh-syntax-highlighting wezterm)

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$*"; }

# --- version sources -------------------------------------------------------
# Latest release tag for a GitHub repo, via the /releases/latest redirect — no API
# token, no jq, no rate-limit headaches: just read where GitHub points us.
gh_latest() {
  local url
  url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    "https://github.com/$1/releases/latest" 2>/dev/null)" || return 0
  printf '%s' "${url##*/tag/}"
}
# apt's candidate (installable) version — what `apt upgrade` would pull.
apt_candidate() { apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/{print $2}'; }
# Latest published version of an npm package (Claude Code ships on npm and via the
# native installer in lockstep).
npm_latest() {
  curl -fsSL "https://registry.npmjs.org/$1/latest" 2>/dev/null \
    | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4
}

# --- per-tool version + changelog lookups (shared by report & summary) -----
# Drop a leading "v" so installed ("1.2.3") and GitHub tags ("v1.2.3") compare.
norm() { printf '%s' "${1#v}"; }

installed_version() {
  case "$1" in
    wezterm)  wezterm    --version 2>/dev/null | awk '{print $2}' ;;
    starship) starship   --version 2>/dev/null | head -1 | awk '{print $2}' ;;
    zoxide)   zoxide     --version 2>/dev/null | awk '{print $2}' ;;
    nvim)     "$BIN/nvim" --version 2>/dev/null | head -1 | awk '{print $2}' ;;
    zed)      zed        --version 2>/dev/null | awk '{print $2}' ;;
    font)     ls "$HOME/.local/share/fonts/JetBrainsMono"/*.ttf >/dev/null 2>&1 && echo present || echo missing ;;
    claude)   claude     --version 2>/dev/null | awk '{print $1}' ;;
  esac
}
latest_version() {
  case "$1" in
    wezterm)  apt_candidate wezterm ;;
    starship) gh_latest starship/starship ;;
    zoxide)   gh_latest ajeetdsouza/zoxide ;;
    nvim)     gh_latest neovim/neovim ;;
    zed)      gh_latest zed-industries/zed ;;
    font)     gh_latest ryanoasis/nerd-fonts ;;
    claude)   npm_latest @anthropic-ai/claude-code ;;
  esac
}
changelog_url() {
  case "$1" in
    wezterm)  echo 'https://wezfurlong.org/wezterm/changelog.html' ;;
    starship) echo 'https://github.com/starship/starship/releases' ;;
    zoxide)   echo 'https://github.com/ajeetdsouza/zoxide/releases' ;;
    nvim)     echo 'https://github.com/neovim/neovim/releases' ;;
    zed)      echo 'https://zed.dev/releases' ;;
    font)     echo 'https://github.com/ryanoasis/nerd-fonts/releases' ;;
    claude)   echo 'https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md' ;;
  esac
}
# "⚠" when old→new crosses a major (or, for 0.x, a minor) — i.e. the bump most
# likely to carry breaking changes. Patch bumps and no-change stay quiet.
bump_flag() {
  local o n; o="$(norm "$1")"; n="$(norm "$2")"
  [ -n "$o" ] && [ -n "$n" ] && [ "$o" != "$n" ] || { echo ' '; return; }
  local oM="${o%%.*}" nM="${n%%.*}" oRest="${o#*.}" nRest="${n#*.}"
  local oMin="${oRest%%.*}" nMin="${nRest%%.*}"
  if [ "$oM" != "$nM" ]; then echo '⚠'; return; fi
  if [ "$oM" = 0 ] && [ "$oMin" != "$nMin" ]; then echo '⚠'; return; fi
  echo ' '
}

# Is tool $1 (installed $2, latest $3) actually behind? Returns 0 (yes) / 1 (no).
# "present" means the font is installed but its version isn't readable from the
# .ttf, so we can't tell it's behind — don't nag about it.
is_behind() {
  [ -z "$3" ]          && return 1   # couldn't fetch latest
  [ "$2" = present ]   && return 1   # font: version not detectable
  [ "$2" = "$3" ]      && return 1   # same version
  return 0
}

# Installed-vs-latest table with a breaking-change flag + release-notes link for
# anything that's behind. Shared by `versions` and the pre-update preview.
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
    info 'Upgrade with:  ./update.sh'
  fi
  return "$any"
}

# ---------------------------------------------------------------------------
cmd_versions() {
  print_status_table
  echo
  info '⚠ = major (or 0.x minor) jump — most likely to carry breaking changes.'
  info 'Upgrade everything to LATEST with:  ./update.sh'
}

# ---------------------------------------------------------------------------
do_upgrades() {
  # apt-managed (includes WezTerm via its Fury repo). --only-upgrade so we don't
  # newly pull anything install.sh chose to leave out.
  info "Upgrading apt packages (needs sudo)…"
  sudo apt-get update -y
  sudo apt-get install --only-upgrade -y "${APT_PKGS[@]}"

  # Starship / zoxide — official installers always fetch latest and overwrite.
  info "Upgrading Starship…"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$BIN"
  info "Upgrading zoxide…"
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
    | sh -s -- --bin-dir "$BIN"

  # Neovim — re-fetch the latest stable release tarball into ~/.local/nvim.
  info "Upgrading Neovim…"
  case "$ARCH" in
    amd64) NVIM_ARCH=x86_64 ;;
    arm64) NVIM_ARCH=arm64 ;;
    *)     NVIM_ARCH="" ;;
  esac
  if [ -z "$NVIM_ARCH" ]; then
    warn "No Neovim build for arch '$ARCH'; skipping"
  else
    curl -fL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" \
      -o /tmp/nvim.tar.gz
    rm -rf "$HOME/.local/nvim"
    mkdir -p "$HOME/.local/nvim"
    tar -xzf /tmp/nvim.tar.gz -C "$HOME/.local/nvim" --strip-components=1
    ln -sf "$HOME/.local/nvim/bin/nvim" "$BIN/nvim"
    rm -f /tmp/nvim.tar.gz
  fi
  # Neovim's plugins update separately, from inside nvim: :lua vim.pack.update()

  # JetBrainsMono Nerd Font — re-download the latest release and refresh the cache.
  info "Upgrading JetBrainsMono Nerd Font…"
  FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
  mkdir -p "$FONT_DIR"
  curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
    -o /tmp/JetBrainsMono.zip
  unzip -oq /tmp/JetBrainsMono.zip -d "$FONT_DIR"
  rm -f /tmp/JetBrainsMono.zip
  fc-cache -f >/dev/null

  # Zed self-updates in the background, so there's nothing to pull here.
  if command -v zed >/dev/null; then
    info "Zed self-updates ($(zed --version 2>/dev/null | head -1)); no action needed"
  fi

  # Claude Code — native installer, self-updating. `claude update` forces it now.
  if command -v claude >/dev/null; then
    info "Updating Claude Code…"
    claude update || warn "claude update failed; it also self-updates on launch"
  fi

  # cheat + keymap (Textual) — keep the shared tools venv current.
  CHEAT_VENV="$HOME/.local/share/cheat/venv"
  if [ -x "$CHEAT_VENV/bin/pip" ]; then
    info "Upgrading Textual (cheat + keymap)…"
    "$CHEAT_VENV/bin/pip" install -q --upgrade textual || warn "Textual upgrade failed"
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
