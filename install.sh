#!/usr/bin/env bash
# Dotfiles installer for Pop!_OS / Ubuntu (Ghostty + Zellij + zsh + Starship)
# Idempotent: safe to re-run. Existing files are backed up before linking.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH="$(dpkg --print-architecture)"          # e.g. amd64
. /etc/os-release                            # provides $VERSION_ID, $ID
BIN="$HOME/.local/bin"
mkdir -p "$BIN" "$HOME/.config"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$*"; }

link() {
  local src="$1" dst="$2"
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

# ---------------------------------------------------------------------------
info "Installing apt packages (needs sudo)…"
sudo apt-get update -y
sudo apt-get install -y \
  zsh git curl unzip ca-certificates fontconfig wl-clipboard \
  zsh-autosuggestions zsh-syntax-highlighting

# ---------------------------------------------------------------------------
info "Installing Ghostty…"
if command -v ghostty >/dev/null; then
  info "ghostty already installed ($(ghostty --version 2>/dev/null | head -1))"
else
  DEB_URL="$(curl -fsSL https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest \
    | grep -oP '"browser_download_url":\s*"\K[^"]*' \
    | grep "_${ARCH}_${VERSION_ID}\.deb$" | head -1 || true)"
  if [ -n "${DEB_URL:-}" ]; then
    tmp="$(mktemp --suffix=.deb)"
    curl -fL "$DEB_URL" -o "$tmp"
    sudo apt-get install -y "$tmp"
    rm -f "$tmp"
  else
    warn "No prebuilt Ghostty .deb for ${ID} ${VERSION_ID}/${ARCH}; see https://ghostty.org/docs/install"
  fi
fi

# ---------------------------------------------------------------------------
info "Installing Zellij…"
if command -v zellij >/dev/null; then
  info "zellij already installed ($(zellij --version))"
else
  case "$ARCH" in
    amd64) ZJ_ARCH=x86_64 ;;
    arm64) ZJ_ARCH=aarch64 ;;
    *)     ZJ_ARCH="" ;;
  esac
  if [ -z "$ZJ_ARCH" ]; then
    warn "No Zellij build for arch '$ARCH'; skipping (see https://github.com/zellij-org/zellij/releases)"
  else
    ZJ_URL="$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest \
      | grep -oP '"browser_download_url":\s*"\K[^"]*zellij-'"$ZJ_ARCH"'-unknown-linux-musl\.tar\.gz' | head -1)"
    curl -fL "$ZJ_URL" -o /tmp/zellij.tar.gz
    tar -xzf /tmp/zellij.tar.gz -C "$BIN" zellij
    chmod +x "$BIN/zellij"
    rm -f /tmp/zellij.tar.gz
  fi
fi

# ---------------------------------------------------------------------------
info "Installing Starship…"
if command -v starship >/dev/null; then
  info "starship already installed ($(starship --version | head -1))"
else
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$BIN"
fi

# ---------------------------------------------------------------------------
info "Installing JetBrainsMono Nerd Font…"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
if [ -d "$FONT_DIR" ] && ls "$FONT_DIR"/*.ttf >/dev/null 2>&1; then
  info "Nerd Font already present"
else
  mkdir -p "$FONT_DIR"
  curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
    -o /tmp/JetBrainsMono.zip
  unzip -oq /tmp/JetBrainsMono.zip -d "$FONT_DIR"
  rm -f /tmp/JetBrainsMono.zip
  fc-cache -f >/dev/null
fi

# ---------------------------------------------------------------------------
info "Linking config files…"
link "$DOTFILES/ghostty/config"        "$HOME/.config/ghostty/config"
link "$DOTFILES/zellij/config.kdl"     "$HOME/.config/zellij/config.kdl"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/zsh/.zshrc"            "$HOME/.zshrc"
link "$DOTFILES/intellij/.ideavimrc"   "$HOME/.ideavimrc"

# ---------------------------------------------------------------------------
ZSH_PATH="$(command -v zsh)"
grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
  info "Setting default shell to zsh (may prompt for password)…"
  chsh -s "$ZSH_PATH" || warn "chsh failed; run: chsh -s $ZSH_PATH"
fi

info "Done. Open Ghostty (or run 'exec zsh') to start using the new setup."
