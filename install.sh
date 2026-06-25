#!/usr/bin/env bash
# Dotfiles installer for Pop!_OS / Ubuntu (WezTerm + Zellij + zsh + Starship)
# Idempotent: safe to re-run. Existing files are backed up before linking.
# Windows uses install.ps1 instead; both share the wezterm/zellij/starship/nvim configs.
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
info "Installing WezTerm…"
if command -v wezterm >/dev/null; then
  info "wezterm already installed ($(wezterm --version))"
else
  # Official Fury APT repo (handles future updates via apt; amd64 + arm64).
  # See https://wezfurlong.org/wezterm/install/linux.html
  curl -fsSL https://apt.fury.io/wez/gpg.key \
    | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
  sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg
  echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
    | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y wezterm
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
info "Installing zoxide…"
# Smarter cd: `z <dir>` jumps to frecent dirs. apt's zoxide is often stale, so
# use the official installer as a user binary in ~/.local/bin.
if command -v zoxide >/dev/null; then
  info "zoxide already installed ($(zoxide --version))"
else
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
    | sh -s -- --bin-dir "$BIN"
fi

# ---------------------------------------------------------------------------
info "Installing Neovim…"
# apt ships an old Neovim (0.9.x); the nvim config needs 0.12+ (vim.pack), so
# install the latest stable release as a user binary in ~/.local/nvim.
if [ -x "$BIN/nvim" ] && "$BIN/nvim" --version | head -1 | grep -qE 'v0\.(1[2-9]|[2-9][0-9])'; then
  info "neovim already installed ($("$BIN/nvim" --version | head -1))"
else
  case "$ARCH" in
    amd64) NVIM_ARCH=x86_64 ;;
    arm64) NVIM_ARCH=arm64 ;;
    *)     NVIM_ARCH="" ;;
  esac
  if [ -z "$NVIM_ARCH" ]; then
    warn "No Neovim build for arch '$ARCH'; skipping (see https://github.com/neovim/neovim/releases)"
  else
    curl -fL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" \
      -o /tmp/nvim.tar.gz
    rm -rf "$HOME/.local/nvim"
    mkdir -p "$HOME/.local/nvim"
    tar -xzf /tmp/nvim.tar.gz -C "$HOME/.local/nvim" --strip-components=1
    ln -sf "$HOME/.local/nvim/bin/nvim" "$BIN/nvim"
    rm -f /tmp/nvim.tar.gz
  fi
fi

# ---------------------------------------------------------------------------
info "Installing tree-sitter CLI…"
# nvim-treesitter (main branch, used by the nvim config) compiles parsers with
# the tree-sitter CLI + a C compiler. cc/gcc come from build-essential on most
# systems; the CLI we install as a user binary.
if [ -x "$BIN/tree-sitter" ]; then
  info "tree-sitter already installed ($("$BIN/tree-sitter" --version))"
else
  case "$ARCH" in
    amd64) TS_ARCH=x64 ;;
    arm64) TS_ARCH=arm64 ;;
    *)     TS_ARCH="" ;;
  esac
  if [ -z "$TS_ARCH" ]; then
    warn "No tree-sitter CLI build for arch '$ARCH'; Neovim treesitter parsers won't compile"
  else
    curl -fL "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-${TS_ARCH}.gz" \
      -o /tmp/tree-sitter.gz
    gunzip -f /tmp/tree-sitter.gz
    install -m 0755 /tmp/tree-sitter "$BIN/tree-sitter"
    rm -f /tmp/tree-sitter
  fi
fi

# ---------------------------------------------------------------------------
info "Installing Zed…"
# Zed is the GUI editor counterpart to Neovim (Catppuccin Mocha + Vim mode, shared
# settings/keymap). The official installer drops it under ~/.local; it self-
# updates afterwards, so we only run it when Zed isn't already present.
if command -v zed >/dev/null; then
  info "zed already installed ($(zed --version 2>/dev/null | head -1))"
else
  curl -f https://zed.dev/install.sh | sh || warn "Zed install failed; see https://zed.dev/docs/linux"
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
link "$DOTFILES/wezterm/wezterm.lua"    "$HOME/.config/wezterm/wezterm.lua"
link "$DOTFILES/zellij/config.kdl"     "$HOME/.config/zellij/config.kdl"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/zsh/.zshrc"            "$HOME/.zshrc"
link "$DOTFILES/intellij/.ideavimrc"   "$HOME/.ideavimrc"
link "$DOTFILES/nvim"                  "$HOME/.config/nvim"
link "$DOTFILES/zed/settings.json"     "$HOME/.config/zed/settings.json"
link "$DOTFILES/zed/keymap.json"       "$HOME/.config/zed/keymap.json"
# Claude Code — settings.json carries the status-line pointer; statusline.js is
# the actual config. Linking settings.json means /config edits land in the repo.
link "$DOTFILES/claude/statusline.js"  "$HOME/.claude/statusline.js"
link "$DOTFILES/claude/settings.json"  "$HOME/.claude/settings.json"

# ---------------------------------------------------------------------------
ZSH_PATH="$(command -v zsh)"
grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
  info "Setting default shell to zsh (may prompt for password)…"
  chsh -s "$ZSH_PATH" || warn "chsh failed; run: chsh -s $ZSH_PATH"
fi

info "Done. Open WezTerm (or run 'exec zsh') to start using the new setup."
