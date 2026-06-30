#!/usr/bin/env bash
# Install the "COSMIC on niri" session — Pop!_OS / Ubuntu only, OPT-IN.
#
# This is NOT part of the main install.sh. It runs COSMIC's desktop components
# (panel, settings, notifications, launcher…) on top of niri, a scrollable-tiling
# Wayland compositor, instead of cosmic-comp. The glue is Drakulix's
# cosmic-ext-extra-sessions, which only works because a recent cosmic-session can
# launch an arbitrary compositor (pop-os/cosmic-session#75 — already in Pop's
# stock cosmic-session 1.0.0).
#
# What it does (all idempotent — safe to re-run):
#   1. apt-installs `just` + niri's build deps
#   2. builds niri from source (not packaged for 24.04) → /usr/local/bin/niri
#   3. builds + installs cosmic-ext-extra-sessions' niri session files
#   4. links this repo's niri/config.kdl → ~/.config/niri/config.kdl
#
# After it finishes: log out and pick "COSMIC on niri" on the greeter.
# See docs/niri.md for the full write-up, keybinds, and troubleshooting.
#
# There is no Windows counterpart: COSMIC and niri are Linux-only, so this lives
# outside the cross-platform install.{sh,ps1} pair by design.
set -euo pipefail

# Reuse install.sh's shared helpers — info/warn/die, $DOTFILES, keep_sudo_fresh, and
# link() (backup-then-symlink). lib.sh is the repo's shared-shell-helpers module;
# sourcing it keeps that logic in ONE place instead of re-implementing it here.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/setup/lib.sh"

SRC="${SRC_DIR:-$HOME/src}"          # where the two source trees are cloned
PREFIX="/usr/local"                  # where the session files + niri binary land

# ---------------------------------------------------------------------------
info "Checking prerequisites…"
# cosmic-session is what actually launches niri (via the start script's
# `cosmic-session niri`). Without it, none of this works — you need COSMIC.
command -v cosmic-session >/dev/null || die "cosmic-session not found — install COSMIC first (this session runs COSMIC's parts on niri)."
command -v cargo >/dev/null          || die "cargo (Rust) not found — install rustup (https://rustup.rs) or the 'cargo' apt package."
command -v git >/dev/null            || die "git not found."

# ---------------------------------------------------------------------------
info "Installing build tools + niri build deps (needs sudo)…"
# Keep sudo fresh: the cargo build below runs for minutes (past sudo's timeout), and
# the `sudo install` afterwards would otherwise re-prompt — or fail non-interactively.
keep_sudo_fresh
# `just` runs cosmic-ext-extra-sessions' recipes. The rest are niri's documented
# build deps for Ubuntu/Debian (https://github.com/YaLTeR/niri — Building).
sudo apt-get update -y
sudo apt-get install -y \
  just gcc clang \
  libudev-dev libgbm-dev libxkbcommon-dev libegl1-mesa-dev libwayland-dev \
  libinput-dev libdbus-1-dev libsystemd-dev libseat-dev libpipewire-0.3-dev \
  libpango1.0-dev libdisplay-info-dev \
  brightnessctl playerctl

# brightnessctl/playerctl back the XF86 brightness + media-key binds in
# config.kdl. COSMIC has no first-party CLI for these; these are the standard
# tools COSMIC itself shells out to, and cosmic-osd still draws the overlay.
# (Volume keys use wpctl, which ships with COSMIC's wireplumber — no install.)

mkdir -p "$SRC"

# ---------------------------------------------------------------------------
info "Building niri from source…"
# niri isn't packaged for Pop!_OS 24.04 (the PPA only covers Ubuntu 25.10+), so
# we build the latest release tag from source and drop the binary on PATH. The
# COSMIC-on-niri start script only needs the `niri` binary itself — none of
# niri's own session/systemd/portal files, since cosmic-session owns the session.
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
# cosmic-ext-extra-sessions ships: the start script, the wayland-session .desktop,
# and (built here) cosmic-ext-alternative-startup — the helper niri spawns at
# startup to hand off to cosmic-comp's session API so the panel/bg/etc. come up.
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
# Same pattern as install.sh: repo is the source of truth, ~/.config points at it.
# link() (from lib.sh) backs up any existing real file, then symlinks; it mkdir -p's
# the parent dir itself.
link "$DOTFILES/niri/config.kdl" "$HOME/.config/niri/config.kdl"

# ---------------------------------------------------------------------------
info "Done. Log out, then pick \"COSMIC on niri\" on the greeter's session menu."
info "Mod is Super. Mod+T terminal · Mod+D launcher · Mod+Shift+E quit. See docs/niri.md."
