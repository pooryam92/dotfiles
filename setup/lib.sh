#!/usr/bin/env bash
# Shared helpers for install.sh (and the extras/ installers) — sourced, never
# run directly: logging, paths, the link helpers, and the per-tool install/fetch actions.

LIBDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # …/setup
DOTFILES="$(dirname "$LIBDIR")"                           # repo root
ARCH="$(dpkg --print-architecture)"          # e.g. amd64
BIN="$HOME/.local/bin"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"

# Only these apt packages are managed, so `update` upgrades just them, not the system.
BASE_APT=(zsh git curl unzip ca-certificates fontconfig wl-clipboard fzf
          zsh-autosuggestions zsh-syntax-highlighting)

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx \033[0m %s\n' "$*" >&2; exit 1; }

# A long source build (the extras' keyd and niri builds) can outlast sudo's timeout and
# surprise-prompt mid-run, so authenticate once and keep the timestamp fresh. Call early.
keep_sudo_fresh() {
  sudo -v || return 1
  local main_pid=$$
  ( while kill -0 "$main_pid" 2>/dev/null; do sudo -n true; sleep 60; done ) 2>/dev/null &
}

# --- config links ----------------------------------------------------------
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

# Copy rather than symlink, for settings.json: the app rewrites it in place (/model
# persists to it) and a symlink would push that churn back into the repo.
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

expand_dst() {
  local p="$1"
  p="${p//\{CONFIG\}/$HOME/.config}"
  p="${p//\{CLAUDE\}/$HOME/.claude}"
  p="${p//\{HOME\}/$HOME}"
  printf '%s' "$p"
}

# links.tsv drives this: linux_dst "-" skips, type `copy` seeds a file the app then owns.
do_links() {
  info "Linking config files…"
  local src type ldst _w dst
  while IFS=$'\t' read -r src type ldst _w; do
    [ "$src" = src ] && continue
    [ -z "$src" ] && continue
    [ "$ldst" = '-' ] && continue
    dst="$(expand_dst "$ldst")"
    if [ "$type" = copy ]; then
      copy_config "$DOTFILES/$src" "$dst"
    else
      link "$DOTFILES/$src" "$dst"
    fi
  done < "$LIBDIR/links.tsv"
}

# --- install / upgrade actions ---------------------------------------------
# Each fetch_* forces the tool to its latest; each install_* is the guard around it.

# WezTerm — nightly .deb from GitHub; the last tagged stable (20240203) is too old for
# this config. Asset names track the Ubuntu base, which Pop!_OS VERSION_ID matches.
fetch_wezterm() {
  local os_ver suffix deb
  os_ver="$(. /etc/os-release && printf '%s' "$VERSION_ID")"
  case "$ARCH" in
    amd64) suffix="" ;;
    arm64) suffix=".arm64" ;;
    *) warn "No WezTerm nightly build for arch '$ARCH'; skipping (see https://github.com/wezterm/wezterm/releases)"; return ;;
  esac
  deb="$(mktemp --suffix=.deb)"   # unpredictable temp name
  curl -fL "https://github.com/wezterm/wezterm/releases/download/nightly/wezterm-nightly.Ubuntu${os_ver}${suffix}.deb" \
    -o "$deb"
  sudo apt-get install -y "$deb"  # resolves deps, unlike dpkg -i
  rm -f "$deb"
  # Drop the frozen Fury APT source earlier installs added.
  sudo rm -f /etc/apt/sources.list.d/wezterm.list /usr/share/keyrings/wezterm-fury.gpg
}
install_wezterm() {
  if command -v wezterm >/dev/null; then
    info "wezterm already installed ($(wezterm --version))"
    if wezterm --version | grep -q 20240203; then
      warn "that is the frozen 20240203 stable; run ./install.sh update to move to nightly"
    fi
  else info "Installing WezTerm…"; fetch_wezterm; fi
}

fetch_zoxide() {
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
    | sh -s -- --bin-dir "$BIN"
}
install_zoxide() {
  if command -v zoxide >/dev/null; then info "zoxide already installed ($(zoxide --version))"
  else info "Installing zoxide…"; fetch_zoxide; fi
}

# fd / ripgrep / bat — apt-packaged. Ubuntu renames two of them (fd→fdfind, bat→batcat),
# so symlink the real names into ~/.local/bin.
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

# The apt neovim (0.9.x) is too old for this config (needs 0.12+ / vim.pack), so install
# the latest stable release tarball under ~/.local/nvim.
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
  tgz="$(mktemp)"
  curl -fL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${nvim_arch}.tar.gz" \
    -o "$tgz"
  rm -rf "$HOME/.local/nvim"
  mkdir -p "$HOME/.local/nvim"
  tar -xzf "$tgz" -C "$HOME/.local/nvim" --strip-components=1
  ln -sf "$HOME/.local/nvim/bin/nvim" "$BIN/nvim"
  rm -f "$tgz"
}
install_nvim() {
  # The regex accepts 0.12+ and any 1.x.
  if [ -x "$BIN/nvim" ] && "$BIN/nvim" --version | head -1 \
       | grep -qE 'v(0\.(1[2-9]|[2-9][0-9]|[0-9]{3,})|[1-9][0-9]*\.)'; then
    info "neovim already installed ($("$BIN/nvim" --version | head -1))"
  else
    info "Installing Neovim…"; fetch_nvim
  fi
}
# The nvim config is colorscheme-only, so the tree-sitter CLI stays out (nvim/README.md).

# --- GUI editors -------------------------------------------------------------
# Zed's official installer drops a self-updating binary under ~/.local; there is no
# fetch_zed because the app upgrades itself.
install_zed() {
  if command -v zed >/dev/null; then
    info "zed already installed ($(zed --version 2>/dev/null | head -1)); it self-updates"
  else
    info "Installing Zed…"
    curl -fsSL https://zed.dev/install.sh | sh \
      || warn "Zed install failed; see https://zed.dev/docs/linux"
  fi
}

# VS Code from Microsoft's apt repo, so `update` upgrades it with the other apt packages.
install_vscode() {
  if command -v code >/dev/null; then
    info "VS Code already installed ($(code --version 2>/dev/null | head -1))"
  else
    info "Installing VS Code from Microsoft's apt repo (needs sudo)…"
    local key
    key="$(mktemp)"
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$key" \
      || { warn "could not fetch Microsoft's signing key; skipping VS Code"; rm -f "$key"; return; }
    sudo install -D -o root -g root -m 644 "$key" /usr/share/keyrings/microsoft.gpg
    rm -f "$key"
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
      | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    sudo apt-get update -y
    sudo apt-get install -y code \
      || { warn "VS Code install failed; see https://code.visualstudio.com/docs/setup/linux"; return; }
  fi
}

# The extensions the VS Code config needs, one id per line in vscode/extensions.txt
# (trailing `# comments` allowed). --force makes --install-extension idempotent, so this
# runs on both install and update and picks up new lines in the file.
install_vscode_extensions() {
  command -v code >/dev/null || { warn "VS Code not installed; skipping extensions"; return; }
  local line ext
  while read -r line || [ -n "$line" ]; do
    ext="${line%%#*}"
    ext="$(printf '%s' "$ext" | tr -d '[:space:]')"
    [ -z "$ext" ] && continue
    info "Installing VS Code extension $ext…"
    code --install-extension "$ext" --force </dev/null \
      || warn "could not install $ext; install it from the Extensions view"
  done < "$DOTFILES/vscode/extensions.txt"
}

# The native installer self-updates (or `claude update`), so run it only when absent.
install_claude() {
  if command -v claude >/dev/null; then info "claude already installed ($(claude --version 2>/dev/null))"
  else info "Installing Claude Code…"; curl -fsSL https://claude.ai/install.sh | bash \
         || warn "Claude Code install failed; see https://docs.anthropic.com/en/docs/claude-code"; fi
}

fetch_font() {
  local zip
  mkdir -p "$FONT_DIR"
  zip="$(mktemp)"
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
