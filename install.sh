#!/bin/bash

# Update and upgrade
apk update && apk upgrade

# Add community repo (if not already added)
echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories

# Install GNOME
apk add gnome gdm
rc-service gdm start
rc-update add gdm

# Install Wi-Fi drivers
apk add linux-firmware-other iwd wpa_supplicant
rc-update add iwd

# Install graphics drivers
apk add mesa-dri-gallium mesa-dri-gallium radeon-ucode

# --- NEW ADDITIONS BELOW --- #

# Install VSCodium (from edge/testing)
apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing vscodium

# Install Rust with rustup (requires curl and sudo)
apk add curl sudo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
rustup default stable

# Install cargo (should be included with rustup)
apk add cargo  # (Optional, but ensures base tools)

# Install virt-manager (libvirt/QEMU/KVM)
apk add virt-manager libvirt qemu qemu-system-x86_64 ebtables dnsmasq
rc-update add libvirtd
rc-service libvirtd start

# Add user to libvirt group (replace 'myuser' with your username)
sudo adduser myuser libvirt
sudo adduser myuser kvm

# Install additional GNOME tools (optional)
apk add gnome-tweaks gnome-software

# Reboot to apply changes (optional)
echo "Installation complete! Reboot recommended."
echo "Run 'sudo reboot' to restart."