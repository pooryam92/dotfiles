#!/usr/bin/env bash
# Shared helpers for install.sh (and the standalone zed/niri installers) — sourced,
# never run directly. Holds logging, path constants, the symlink helper, and the
# per-tool install/upgrade actions. Which configs link where lives in links.tsv;
# which tools get installed is the explicit install_* calls in install.sh.

# This lib lives in setup/ alongside the manifests; the config sources it links live
# one level up at the repo root.
LIBDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # …/setup
DOTFILES="$(dirname "$LIBDIR")"                           # repo root
ARCH="$(dpkg --print-architecture)"          # e.g. amd64
BIN="$HOME/.local/bin"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"

# Base apt packages install.sh manages — targeted so `update` upgrades just these,
# not the whole system.
BASE_APT=(zsh git curl unzip ca-certificates fontconfig wl-clipboard fzf
          zsh-autosuggestions zsh-syntax-highlighting)

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx \033[0m %s\n' "$*" >&2; exit 1; }

# Authenticate sudo once now, then keep its timestamp fresh in the background until
# this script exits. A long source build (keyd here, or niri's cargo build) can
# outlast sudo's default timeout; without this the next `sudo` mid-run surprise-prompts
# for a password — or fails outright when non-interactive. Call once, early.
keep_sudo_fresh() {
  sudo -v || return 1
  local main_pid=$$
  ( while kill -0 "$main_pid" 2>/dev/null; do sudo -n true; sleep 60; done ) 2>/dev/null &
}

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

# Copy a repo file to a target (not a symlink), overwriting whatever is there but
# backing up a real existing file first. Used for settings.json: the app rewrites it
# in place (e.g. /model persists to it), and a symlink would push that churn back
# into the repo. A copy seeds our defaults, then lets the live file diverge locally.
copy_config() {
  local src="$1" dst="$2"
  [ -e "$src" ] || { warn "source missing, skipping: $src"; return; }
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"                               # old symlink into the repo — no data to keep
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%s)"
    warn "backed up existing $dst"
  fi
  cp "$src" "$dst"
  info "copied $dst <- $src"
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
# The `type` column picks the strategy: dir/file symlink live, `copy` seeds a file the
# app owns afterward (claude's settings.json — kept a copy so /model edits don't churn
# the repo).
do_links() {
  info "Linking config files…"
  local src type ldst _w dst
  while IFS=$'\t' read -r src type ldst _w; do
    [ "$src" = src ] && continue          # header
    [ -z "$src" ] && continue
    [ "$ldst" = '-' ] && continue         # not linked on Linux (e.g. pwsh profile)
    dst="$(expand_dst "$ldst")"
    if [ "$type" = copy ]; then
      copy_config "$DOTFILES/$src" "$dst"
    else
      link "$DOTFILES/$src" "$dst"
    fi
  done < "$LIBDIR/links.tsv"
}

# --- install / upgrade actions ---------------------------------------------
# Each fetch_* forces the tool to its latest (used by `update`). Each install_*
# is the install-once guard around it (used by `install`).

# WezTerm — nightly .deb from GitHub. Upstream hasn't tagged a release since 20240203
# (the Fury APT repo is frozen there), and that build has an initial-configure bug
# under niri that needed a window-rule workaround; nightly is the maintained channel.
# Windows mirrors this with scoop's wezterm-nightly. Asset names track the Ubuntu
# base, which Pop!_OS VERSION_ID matches (24.04 → Ubuntu24.04).
fetch_wezterm() {
  local os_ver suffix deb
  os_ver="$(. /etc/os-release && printf '%s' "$VERSION_ID")"
  case "$ARCH" in
    amd64) suffix="" ;;
    arm64) suffix=".arm64" ;;
    *) warn "No WezTerm nightly build for arch '$ARCH'; skipping (see https://github.com/wezterm/wezterm/releases)"; return ;;
  esac
  deb="$(mktemp --suffix=.deb)"   # unpredictable temp name, like fetch_nvim
  curl -fL "https://github.com/wezterm/wezterm/releases/download/nightly/wezterm-nightly.Ubuntu${os_ver}${suffix}.deb" \
    -o "$deb"
  sudo apt-get install -y "$deb"  # local-file install; resolves deps unlike dpkg -i
  rm -f "$deb"
  # One-time cleanup: drop the Fury APT source earlier installs used, so apt stops
  # polling a repo that's frozen at 20240203.
  sudo rm -f /etc/apt/sources.list.d/wezterm.list /usr/share/keyrings/wezterm-fury.gpg
}
install_wezterm() {
  if command -v wezterm >/dev/null; then info "wezterm already installed ($(wezterm --version))"
  else info "Installing WezTerm…"; fetch_wezterm; fi
}

# zoxide — the official installer always fetches latest and overwrites, so the
# same fetch doubles as the upgrade path.
fetch_zoxide() {
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
    | sh -s -- --bin-dir "$BIN"
}
install_zoxide() {
  if command -v zoxide >/dev/null; then info "zoxide already installed ($(zoxide --version))"
  else info "Installing zoxide…"; fetch_zoxide; fi
}

# fd / ripgrep / bat — apt-packaged and current enough on 24.04, so no GitHub
# downloads. Ubuntu renames two of the binaries to dodge old name clashes
# (fd→fdfind, bat→batcat); symlink the real names into ~/.local/bin so the shell
# config (fzf wiring) and muscle memory can use `fd`/`bat` like everywhere else.
# Updates ride the apt --only-upgrade line in install.sh's cmd_update.
fetch_fd()  { sudo apt-get install -y fd-find; ln -sf "$(command -v fdfind)" "$BIN/fd"; }
install_fd() {
  if command -v fd >/dev/null; then info "fd already installed ($(fd --version))"
  else info "Installing fd…"; fetch_fd; fi
}
fetch_rg()  { sudo apt-get install -y ripgrep; }
install_rg() {
  if command -v rg >/dev/null; then info "ripgrep already installed ($(rg --version | head -1))"
  else info "Installing ripgrep…"; fetch_rg; fi
}
fetch_bat() { sudo apt-get install -y bat; ln -sf "$(command -v batcat)" "$BIN/bat"; }
install_bat() {
  if command -v bat >/dev/null; then info "bat already installed ($(bat --version))"
  else info "Installing bat…"; fetch_bat; fi
}

# Neovim — apt ships an old build (0.9.x); the nvim config needs 0.12+ (vim.pack), so
# install the latest stable release as a user binary in ~/.local/nvim.
fetch_nvim() {
  local nvim_arch tgz
  case "$ARCH" in
    amd64) nvim_arch=x86_64 ;;
    arm64) nvim_arch=arm64 ;;
    *)     nvim_arch="" ;;
  esac
  if [ -z "$nvim_arch" ]; then
    warn "No Neovim build for arch '$ARCH'; skipping (see https://github.com/neovim/neovim/releases)"
    return
  fi
  tgz="$(mktemp)"   # unpredictable, mode-600 temp — avoids a fixed /tmp name (collision + symlink-attack safe)
  curl -fL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${nvim_arch}.tar.gz" \
    -o "$tgz"
  rm -rf "$HOME/.local/nvim"
  mkdir -p "$HOME/.local/nvim"
  tar -xzf "$tgz" -C "$HOME/.local/nvim" --strip-components=1
  ln -sf "$HOME/.local/nvim/bin/nvim" "$BIN/nvim"
  rm -f "$tgz"
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
# NOTE: the nvim config is colorscheme-only (no treesitter/Telescope) and stays that
# way by design — nvim's job here is quick edits, commit messages, and Ctrl+X Ctrl+E;
# Zed/JetBrains carry project editing (see nvim/README.md). fd/rg/bat above are for the
# SHELL (fzf wiring), not nvim; only the tree-sitter CLI remains uninstalled.

# keyd — remaps keys at the evdev layer, so it works under any compositor (niri,
# cosmic-comp), X11, and the TTY. Used for CapsLock→Esc/Ctrl and LeftCtrl→Super (this
# laptop's Super key is physically dead — see keyd/README.md). Not packaged for Pop!_OS
# 24.04, so build from source like Neovim. Linux-only (PowerToys Keyboard Manager covers
# remapping on Windows) and install-once: `update` never rebuilds it.
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

# Zed — the GUI editor — is NOT managed here. It's a GUI app, installed on its own
# by zed/install-zed.sh (mirroring niri's standalone installer), so it stays out of
# the CLI install/update loops. Its config is still symlinked via links.tsv.

# Claude Code — Anthropic's CLI. The native installer self-updates (or `claude
# update`), so we only run it when absent. Its config is linked from this repo.
install_claude() {
  if command -v claude >/dev/null; then info "claude already installed ($(claude --version 2>/dev/null))"
  else info "Installing Claude Code…"; curl -fsSL https://claude.ai/install.sh | bash \
         || warn "Claude Code install failed; see https://docs.anthropic.com/en/docs/claude-code"; fi
}

# JetBrainsMono Nerd Font — re-download the latest release and refresh the cache.
fetch_font() {
  local zip
  mkdir -p "$FONT_DIR"
  zip="$(mktemp)"   # unpredictable, mode-600 temp — avoids a fixed /tmp name
  curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
    -o "$zip"
  unzip -oq "$zip" -d "$FONT_DIR"
  rm -f "$zip"
  fc-cache -f >/dev/null
}
install_font() {
  if [ -d "$FONT_DIR" ] && ls "$FONT_DIR"/*.ttf >/dev/null 2>&1; then info "Nerd Font already present"
  else info "Installing JetBrainsMono Nerd Font…"; fetch_font; fi
}
