#!/bin/bash

# This script sets up Broadcom BCM4352 Wi-Fi and Bluetooth on Fedora.
# It needs to be run with root privileges (sudo).


if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

# --- 1. Enable RPM Fusion Repositories ---
dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# --- 2. Install Broadcom Wi-Fi Driver ---
dnf install -y akmod-wl kernel-devel

# --- 3. Download and Install Bluetooth Firmware ---
git clone https://github.com/winterheart/broadcom-bt-firmware.git /tmp/broadcom-bt-firmware
cp /tmp/broadcom-bt-firmware/brcm/*.hcd /lib/firmware/brcm/

# --- 4. Clean Up ---
rm -rf /tmp/broadcom-bt-firmware

# --- Final Instructions ---
echo "-------------------------------------------------------------"
echo "Setup is complete. A reboot is required to load the new drivers and firmware."
echo "Please reboot your system now."
echo "-------------------------------------------------------------"
