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

# Install GNOME
setup-desktop gnome

# Install essential tools
apk add vscodium btop curl nano fastfetch

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
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

# Reboot
reboot