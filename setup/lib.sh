#!/usr/bin/env bash
# Shared helpers for install.sh and update.sh — sourced by both, never run directly.
# Holds the things that used to be copy-pasted between the two scripts: logging,
# path constants, the symlink helper, the version-report machinery, and the per-tool
# install/upgrade actions. The DATA (which tools, where they come from, where configs
# link to) lives in tools.tsv / links.tsv; this file holds the ACTIONS.

# This lib lives in setup/ alongside update.sh and the manifests; the config sources
# it links live one level up at the repo root.
LIBDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # …/setup
DOTFILES="$(dirname "$LIBDIR")"                           # repo root
ARCH="$(dpkg --print-architecture)"          # e.g. amd64
BIN="$HOME/.local/bin"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"

# Base apt packages install.sh manages — targeted so update.sh upgrades just these,
# not the whole system.
BASE_APT=(zsh git curl unzip ca-certificates fontconfig wl-clipboard fzf
          zsh-autosuggestions zsh-syntax-highlighting)

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$*"; }

# --- config links ----------------------------------------------------------
# Symlink a repo file/dir to a target, backing up any existing real file first.
link() {
  local src="$1" dst="$2"
  [ -e "$src" ] || { warn "source missing, skipping: $src"; return; }
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%s)"
    warn "backed up existing $dst"
  fi
  ln -s "$src" "$dst"
  info "linked $dst -> $src"
}

# Expand the links.tsv destination tokens to real Linux paths.
expand_dst() {
  local p="$1"
  p="${p//\{CONFIG\}/$HOME/.config}"
  p="${p//\{CLAUDE\}/$HOME/.claude}"
  p="${p//\{HOME\}/$HOME}"
  printf '%s' "$p"
}

# Link every config in links.tsv (the linux_dst column; "-" means skip on Linux).
# Linking claude's settings.json means /config edits land in the repo.
do_links() {
  info "Linking config files…"
  local src type ldst _w dst
  while IFS=$'\t' read -r src type ldst _w; do
    [ "$src" = src ] && continue          # header
    [ -z "$src" ] && continue
    [ "$ldst" = '-' ] && continue         # not linked on Linux (e.g. pwsh profile)
    dst="$(expand_dst "$ldst")"
    link "$DOTFILES/$src" "$dst"
  done < "$LIBDIR/links.tsv"
}

# --- version reporting (used by update.sh) ---------------------------------
# Read column $2 of the tools.tsv row named $1 (cols: name source scoop changelog desc).
tool_col() { awk -F'\t' -v n="$1" -v c="$2" 'NR>1 && $1==n {print $c}' "$LIBDIR/tools.tsv"; }

# Every tool we manage, in tools.tsv order.
mapfile -t TOOLS < <(awk -F'\t' 'NR>1{print $1}' "$LIBDIR/tools.tsv")

# Latest GitHub release tag via the /releases/latest redirect — no API token, no jq.
gh_latest() {
  local url
  url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    "https://github.com/$1/releases/latest" 2>/dev/null)" || return 0
  printf '%s' "${url##*/tag/}"
}
apt_candidate() { apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/{print $2}'; }
npm_latest() {
  curl -fsSL "https://registry.npmjs.org/$1/latest" 2>/dev/null \
    | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4
}

# Drop a leading "v" so installed ("1.2.3") and GitHub tags ("v1.2.3") compare.
norm() { printf '%s' "${1#v}"; }

# Generic version reader: from line 1 of `<bin> --version`, take the first
# whitespace-delimited token containing a digit. Works across every format we have —
# starship/zoxide "tool 1.2.3", nvim "NVIM v0.12.3", zed "Zed 1.8.2 <hash>",
# wezterm "wezterm 20240203-110809-…" (date-based), claude "2.1.195 (Claude Code)".
detect_version() {
  "$1" --version 2>/dev/null | head -1 \
    | grep -oE '[^[:space:]]*[0-9][^[:space:]]*' | head -1
}

installed_version() {
  case "$1" in
    nvim)  detect_version "$BIN/nvim" ;;
    font)  ls "$FONT_DIR"/*.ttf >/dev/null 2>&1 && echo present || echo missing ;;
    *)     detect_version "$1" ;;        # binary name == tool name (wezterm, zed, …)
  esac
}
latest_version() {
  local src; src="$(tool_col "$1" 2)"
  case "$src" in
    apt:*) apt_candidate "${src#apt:}" ;;
    gh:*)  gh_latest    "${src#gh:}" ;;
    npm:*) npm_latest   "${src#npm:}" ;;
  esac
}
changelog_url() { tool_col "$1" 4; }

# "⚠" when old→new crosses a major (or, for 0.x, a minor) — the bump most likely to
# carry breaking changes. Patch bumps and no-change stay quiet.
bump_flag() {
  local o n; o="$(norm "$1")"; n="$(norm "$2")"
  [ -n "$o" ] && [ -n "$n" ] && [ "$o" != "$n" ] || { echo ' '; return; }
  local oM="${o%%.*}" nM="${n%%.*}" oRest="${o#*.}" nRest="${n#*.}"
  local oMin="${oRest%%.*}" nMin="${nRest%%.*}"
  if [ "$oM" != "$nM" ]; then echo '⚠'; return; fi
  if [ "$oM" = 0 ] && [ "$oMin" != "$nMin" ]; then echo '⚠'; return; fi
  echo ' '
}

# Is tool $1 (installed $2, latest $3) actually behind? 0 (yes) / 1 (no).
# "present" = font installed but version not readable from the .ttf — don't nag.
is_behind() {
  [ -z "$3" ]        && return 1   # couldn't fetch latest
  [ "$2" = present ] && return 1   # font: version not detectable
  [ "$2" = "$3" ]    && return 1   # same version
  return 0
}

# --- install / upgrade actions ---------------------------------------------
# Each fetch_* forces the tool to its latest (used by update.sh). Each install_*
# is the install-once guard around it (used by install.sh).

# WezTerm via the official Fury APT repo (handles future updates via apt; amd64 +
# arm64). See https://wezfurlong.org/wezterm/install/linux.html
fetch_wezterm() {
  curl -fsSL https://apt.fury.io/wez/gpg.key \
    | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
  sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg
  echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
    | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y wezterm
}
install_wezterm() {
  if command -v wezterm >/dev/null; then info "wezterm already installed ($(wezterm --version))"
  else info "Installing WezTerm…"; fetch_wezterm; fi
}

# Starship / zoxide — official installers always fetch latest and overwrite, so the
# same fetch doubles as the upgrade path.
fetch_starship() { curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$BIN"; }
install_starship() {
  if command -v starship >/dev/null; then info "starship already installed ($(starship --version | head -1))"
  else info "Installing Starship…"; fetch_starship; fi
}
fetch_zoxide() {
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
    | sh -s -- --bin-dir "$BIN"
}
install_zoxide() {
  if command -v zoxide >/dev/null; then info "zoxide already installed ($(zoxide --version))"
  else info "Installing zoxide…"; fetch_zoxide; fi
}

# Neovim — apt ships an old build (0.9.x); the nvim config needs 0.12+ (vim.pack), so
# install the latest stable release as a user binary in ~/.local/nvim.
fetch_nvim() {
  local nvim_arch
  case "$ARCH" in
    amd64) nvim_arch=x86_64 ;;
    arm64) nvim_arch=arm64 ;;
    *)     nvim_arch="" ;;
  esac
  if [ -z "$nvim_arch" ]; then
    warn "No Neovim build for arch '$ARCH'; skipping (see https://github.com/neovim/neovim/releases)"
    return
  fi
  curl -fL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${nvim_arch}.tar.gz" \
    -o /tmp/nvim.tar.gz
  rm -rf "$HOME/.local/nvim"
  mkdir -p "$HOME/.local/nvim"
  tar -xzf /tmp/nvim.tar.gz -C "$HOME/.local/nvim" --strip-components=1
  ln -sf "$HOME/.local/nvim/bin/nvim" "$BIN/nvim"
  rm -f /tmp/nvim.tar.gz
  # Neovim's plugins update separately, from inside nvim: :lua vim.pack.update()
}
install_nvim() {
  # Accept 0.12–0.99, 0.100+, and any 1.x+ as "new enough".
  if [ -x "$BIN/nvim" ] && "$BIN/nvim" --version | head -1 \
       | grep -qE 'v(0\.(1[2-9]|[2-9][0-9]|[0-9]{3,})|[1-9][0-9]*\.)'; then
    info "neovim already installed ($("$BIN/nvim" --version | head -1))"
  else
    info "Installing Neovim…"; fetch_nvim
  fi
}
# NOTE: the nvim config is colorscheme-only (no treesitter/Telescope), so the
# tree-sitter CLI, ripgrep and fd are intentionally NOT installed — add them back if
# you grow the nvim config (see docs/nvim.md). install.ps1 mirrors this.

# keyd — remaps keys at the evdev layer, so it works under any compositor (niri,
# cosmic-comp), X11, and the TTY. Used for CapsLock→Esc/Ctrl and LeftCtrl→Super (this
# laptop's Super key is physically dead — see docs/keyd.md). Not packaged for Pop!_OS
# 24.04, so build from source like Neovim. Linux-only (Windows uses PowerToys Keyboard
# Manager). Install-only: not version-tracked in update.sh.
install_keyd() {
  if command -v keyd >/dev/null; then
    info "keyd already installed ($(keyd --version 2>/dev/null | head -1))"
  else
    info "Installing keyd (key remapper)…"
    sudo apt-get install -y build-essential
    local src="${SRC_DIR:-$HOME/src}/keyd"
    if [ -d "$src/.git" ]; then
      git -C "$src" pull --ff-only || warn "could not update keyd; building current checkout"
    else
      git clone https://github.com/rvaiya/keyd "$src"
    fi
    ( cd "$src" && make && sudo make install )
    sudo systemctl enable --now keyd
  fi
  # Config: the repo is the source of truth. /etc is root-owned and keyd starts at
  # boot (before $HOME may be mounted), so copy the file rather than symlink it.
  sudo install -Dm644 "$DOTFILES/keyd/default.conf" /etc/keyd/default.conf
  sudo keyd reload 2>/dev/null || warn "keyd reload failed; run 'sudo keyd reload' once the service is up"
}

# Zed — GUI editor counterpart to Neovim. The installer drops it under ~/.local and
# it self-updates afterwards, so there's no fetch_* upgrade path.
install_zed() {
  if command -v zed >/dev/null; then info "zed already installed ($(zed --version 2>/dev/null | head -1))"
  else info "Installing Zed…"; curl -fsSL https://zed.dev/install.sh | sh \
         || warn "Zed install failed; see https://zed.dev/docs/linux"; fi
}

# Claude Code — Anthropic's CLI. The native installer self-updates (or `claude
# update`), so we only run it when absent. Its config is linked from this repo.
install_claude() {
  if command -v claude >/dev/null; then info "claude already installed ($(claude --version 2>/dev/null))"
  else info "Installing Claude Code…"; curl -fsSL https://claude.ai/install.sh | bash \
         || warn "Claude Code install failed; see https://docs.anthropic.com/en/docs/claude-code"; fi
}

# JetBrainsMono Nerd Font — re-download the latest release and refresh the cache.
fetch_font() {
  mkdir -p "$FONT_DIR"
  curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
    -o /tmp/JetBrainsMono.zip
  unzip -oq /tmp/JetBrainsMono.zip -d "$FONT_DIR"
  rm -f /tmp/JetBrainsMono.zip
  fc-cache -f >/dev/null
}
install_font() {
  if [ -d "$FONT_DIR" ] && ls "$FONT_DIR"/*.ttf >/dev/null 2>&1; then info "Nerd Font already present"
  else info "Installing JetBrainsMono Nerd Font…"; fetch_font; fi
}
