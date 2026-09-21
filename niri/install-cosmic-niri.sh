#!/usr/bin/env bash
# Installs the "COSMIC on niri" session: COSMIC's desktop parts (panel, settings,
# launcher…) running on niri instead of cosmic-comp. Log out afterwards and pick it
# on the greeter. See niri/README.md.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/setup/lib.sh"

SRC="${SRC_DIR:-$HOME/src}"
PREFIX="/usr/local"

# ---------------------------------------------------------------------------
info "Checking prerequisites…"
# cosmic-session is what launches niri, so COSMIC has to be installed already.
command -v cosmic-session >/dev/null || die "cosmic-session not found — install COSMIC first (this session runs COSMIC's parts on niri)."
command -v cargo >/dev/null          || die "cargo (Rust) not found — install rustup (https://rustup.rs) or the 'cargo' apt package."
command -v git >/dev/null            || die "git not found."

# ---------------------------------------------------------------------------
info "Installing build tools + niri build deps (needs sudo)…"
# The cargo build below runs for minutes, past sudo's timeout.
keep_sudo_fresh
# just runs cosmic-ext-extra-sessions' recipes; the rest are niri's build deps.
# brightnessctl/playerctl back the brightness + media-key binds in config.kdl.
sudo apt-get update -y
sudo apt-get install -y \
  just gcc clang \
  libudev-dev libgbm-dev libxkbcommon-dev libegl1-mesa-dev libwayland-dev \
  libinput-dev libdbus-1-dev libsystemd-dev libseat-dev libpipewire-0.3-dev \
  libpango1.0-dev libdisplay-info-dev \
  brightnessctl playerctl

mkdir -p "$SRC"

# ---------------------------------------------------------------------------
info "Building niri from source…"
# niri isn't packaged for Pop 24.04, so build the latest release tag from source.
# Only the niri binary is needed — cosmic-session owns the session.
if [ -d "$SRC/niri/.git" ]; then
  info "niri checkout exists — pulling latest"
  git -C "$SRC/niri" pull --ff-only || warn "could not fast-forward niri; building current checkout"
else
  git clone https://github.com/YaLTeR/niri.git "$SRC/niri"
fi
( cd "$SRC/niri" && cargo build --release )
sudo install -Dm0755 "$SRC/niri/target/release/niri" "$PREFIX/bin/niri"
info "installed $($PREFIX/bin/niri --version)"

# ---------------------------------------------------------------------------
info "Building + installing the COSMIC-on-niri session…"
# Ships the start script and the session .desktop, plus cosmic-ext-alternative-startup —
# the helper that hands off to cosmic-comp's session API.
if [ -d "$SRC/cosmic-ext-extra-sessions/.git" ]; then
  info "cosmic-ext-extra-sessions checkout exists — pulling latest"
  git -C "$SRC/cosmic-ext-extra-sessions" pull --ff-only \
    || warn "could not fast-forward cosmic-ext-extra-sessions; using current checkout"
  git -C "$SRC/cosmic-ext-extra-sessions" submodule update --init
else
  git clone https://github.com/Drakulix/cosmic-ext-extra-sessions.git "$SRC/cosmic-ext-extra-sessions"
  git -C "$SRC/cosmic-ext-extra-sessions" submodule update --init
fi
( cd "$SRC/cosmic-ext-extra-sessions" \
    && just build \
    && sudo just install-niri )

# ---------------------------------------------------------------------------
info "Linking niri config…"
# link() backs up any existing real file, then symlinks.
link "$DOTFILES/niri/config.kdl" "$HOME/.config/niri/config.kdl"

# ---------------------------------------------------------------------------
info "Done. Log out, then pick \"COSMIC on niri\" on the greeter's session menu."
info "Mod is Super. Mod+T terminal · Mod+D launcher · Mod+Shift+E quit. See niri/README.md."
