#!/usr/bin/env bash
# Dotfiles installer for Pop!_OS / Ubuntu (WezTerm + zsh + Starship)
# Idempotent: safe to re-run. Existing files are backed up before linking.
# Windows uses install.ps1 instead; both share the wezterm/starship/nvim configs.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH="$(dpkg --print-architecture)"          # e.g. amd64
BIN="$HOME/.local/bin"
mkdir -p "$BIN" "$HOME/.config"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$*"; }

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

# ---------------------------------------------------------------------------
info "Installing apt packages (needs sudo)…"
sudo apt-get update -y
sudo apt-get install -y \
  zsh git curl unzip ca-certificates fontconfig wl-clipboard fzf \
  zsh-autosuggestions zsh-syntax-highlighting python3 python3-venv

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
# Accept 0.12–0.99, 0.100+, and any 1.x+ as "new enough" (config needs 0.12+).
if [ -x "$BIN/nvim" ] && "$BIN/nvim" --version | head -1 | grep -qE 'v(0\.(1[2-9]|[2-9][0-9]|[0-9]{3,})|[1-9][0-9]*\.)'; then
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
# NOTE: the nvim config is colorscheme-only (no treesitter/Telescope), so the
# tree-sitter CLI, ripgrep and fd are intentionally NOT installed — add them back
# if you grow the nvim config (see docs/nvim.md). install.ps1 mirrors this.

# ---------------------------------------------------------------------------
info "Installing Zed…"
# Zed is the GUI editor counterpart to Neovim (Vim mode, shared settings/keymap).
# The official installer drops it under ~/.local; it self-updates afterwards, so
# we only run it when Zed isn't already present.
if command -v zed >/dev/null; then
  info "zed already installed ($(zed --version 2>/dev/null | head -1))"
else
  curl -fsSL https://zed.dev/install.sh | sh || warn "Zed install failed; see https://zed.dev/docs/linux"
fi

# ---------------------------------------------------------------------------
info "Installing Claude Code…"
# Anthropic's CLI. The native installer drops it under ~/.local/share/claude and
# symlinks ~/.local/bin/claude; it self-updates afterwards (or `./update.sh`), so
# we only run it when claude isn't already present. Its config (settings.json,
# statusline.js) is linked from this repo below.
if command -v claude >/dev/null; then
  info "claude already installed ($(claude --version 2>/dev/null))"
else
  curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code install failed; see https://docs.anthropic.com/en/docs/claude-code"
fi

# ---------------------------------------------------------------------------
info "Building the cheat tool's Python venv (Textual TUI)…"
# `cheat` is a Python + Textual app (the tools/cheat/ package). Pop!_OS ships a
# PEP-668 "externally managed" Python, so Textual can't be a plain `pip --user`
# install — it lives in a dedicated venv instead. The shell `cheat` wrapper prefers
# this interpreter and falls back to the system python3 (plain-text mode) without it.
# `keymap` (tools/keymap/keymap.py) is the second tool in the suite and shares this
# same venv — so installing Textual once covers both TUIs.
CHEAT_VENV="$HOME/.local/share/cheat/venv"
if "$CHEAT_VENV/bin/python" -c "import textual" 2>/dev/null; then
  info "cheat venv already has Textual"
else
  python3 -m venv "$CHEAT_VENV"
  "$CHEAT_VENV/bin/pip" install -q --upgrade pip textual \
    || warn "Textual install failed; 'cheat' still works in plain-text mode"
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
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/zsh/.zshrc"            "$HOME/.zshrc"
link "$DOTFILES/intellij/.ideavimrc"   "$HOME/.ideavimrc"
link "$DOTFILES/nvim"                  "$HOME/.config/nvim"
link "$DOTFILES/zed/settings.json"     "$HOME/.config/zed/settings.json"
link "$DOTFILES/zed/keymap.json"       "$HOME/.config/zed/keymap.json"
# The `cheat` command: the tools/cheat/ package (data/content/cli) behind a thin
# cheat.py entry, launched from both shells. We link the entry plus its data —
# entries (cheat.tsv) and category index / learning order (cheat-index.tsv).
# Textual lives in the venv built above.
link "$DOTFILES/tools/cheat/cheat.py"        "$HOME/.config/cheat.py"
link "$DOTFILES/tools/cheat/cheat.tsv"       "$HOME/.config/cheat.tsv"
link "$DOTFILES/tools/cheat/cheat-index.tsv" "$HOME/.config/cheat-index.tsv"
# The `keymap` command: the tools/keymap/ package behind a thin keymap.py entry,
# reading your shell history into a usage heatmap. It reuses cheat's Textual venv
# above — no extra dependency — so it only needs its own entry linked.
link "$DOTFILES/tools/keymap/keymap.py"      "$HOME/.config/keymap.py"
# Both entries are thin: they put the repo's tools/ dir on sys.path by resolving
# their own symlink back into the repo (Path(__file__).resolve()), then import
# their package and the shared tools/tui/ browser. That same trick locates the
# cheat data above — so neither the packages nor tui/ need symlinks of their own.
# Claude Code — settings.json carries the status-line pointer; statusline.js is
# the actual config. Linking settings.json means /config edits land in the repo.
# commands/ holds repo-managed slash commands (e.g. /keymap — the agent that
# turns keymap's data into proposed dotfiles tweaks).
link "$DOTFILES/claude/statusline.js"  "$HOME/.claude/statusline.js"
link "$DOTFILES/claude/settings.json"  "$HOME/.claude/settings.json"
link "$DOTFILES/claude/commands/keymap.md" "$HOME/.claude/commands/keymap.md"

# ---------------------------------------------------------------------------
ZSH_PATH="$(command -v zsh)"
grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
  info "Setting default shell to zsh (may prompt for password)…"
  chsh -s "$ZSH_PATH" || warn "chsh failed; run: chsh -s $ZSH_PATH"
fi

info "Done. Open WezTerm (or run 'exec zsh') to start using the new setup."
