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
apk add build-base perl wget tar
wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
tar -xzf install-tl-unx.tar.gz
cd install-tl-*
./install-tl --scheme=full
cd ..
rm -rf install-tl-* install-tl-unx.tar.gz

# Add LaTeX to PATH
echo 'export PATH=/usr/local/texlive/2024/bin/x86_64-linux:$PATH' >> /etc/profile
source /etc/profile

# Install Texmaker dependencies
apk add qt5-qtbase-dev qt5-qttools-dev poppler-qt5-dev make g++
export QT_SELECT=5
export PATH="/usr/lib/qt5/bin:$PATH"

# Download and compile Texmaker from source
wget https://www.xm1math.net/texmaker/texmaker-5.1.4.tar.bz2
tar -xf texmaker-5.1.4.tar.bz2
cd texmaker-5.1.4
qmake-qt5 PREFIX=/usr
make
make install
cd ..
rm -rf texmaker-5.1.4*

# Reboot
reboot