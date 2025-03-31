#!/bin/bash

# Enable strict mode:
set -ex

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Try 'sudo sh install.sh'"
    exit 1
fi

# Add Alpine's edge/testing repo
echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Update & upgrade
apk update && apk upgrade

# Fix UTF-8 locale for btop (Alpine-specific method)
apk add musl-locales
echo "LANG=en_US.UTF-8" > /etc/locale.conf
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Install GNOME
setup-desktop gnome

# Install essential tools (now including btop)
apk add vscodium btop curl nano fastfetch

# Install Rust (press Enter automatically)
printf '\n' | sh -s -- --help | grep -q rustup && {
    printf '\n' | curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}
source "$HOME/.cargo/env"
apk add cargo

# Remove unnecessary GNOME apps
apk del gnome-weather gnome-clocks gnome-contacts cheese gnome-tour gnome-music \
      gnome-calendar yelp simple-scan xsane totem snapshot

# Install LaTeX (Full)
apk add build-base perl wget tar gnupg
wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
tar -xzf install-tl-unx.tar.gz
cd install-tl-*
TEXLIVE_INSTALL_PREFIX=/usr/local ./install-tl --scheme=full --no-interaction
cd ..
rm -rf install-tl-* install-tl-unx.tar.gz

# Create symlinks for all binaries
ln -s /usr/local/texlive/*/bin/* /usr/local/bin/

# Verify installation
pdflatex --version
latexmk --version

# Install LaTeX tools for VSCodium
apk add latexmk chktex

# Install GitHub Desktop via Flatpak
apk add flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub io.github.shiftey.Desktop -y

# Make UTF-8 locale persistent
echo "export LANG=en_US.UTF-8" >> /etc/profile
echo "export LC_ALL=en_US.UTF-8" >> /etc/profile

# Reboot
reboot