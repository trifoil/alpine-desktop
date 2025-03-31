#!/bin/bash

# Enable strict mode:
# -e  Exit immediately if a command exits with a non-zero status
# -x  Print commands and their arguments as they are executed
set -ex

# Check if the script is running as root (user ID 0)
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Try 'sudo sh install.sh'"
    exit 1  # Exit with error code 1 if not root
fi

# Add Alpine Linux's edge/testing repository to the package manager's sources
echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Update the package index and upgrade all installed packages
apk update && apk upgrade

# Install GNOME desktop environment using Alpine's setup-desktop utility
setup-desktop gnome

# Install various packages:
apk add vscodium  # VS Code editor (open-source version)
apk add btop      # Advanced system monitor
apk add curl nano fastfetch  # curl for downloads, nano text editor, fastfetch system info tool

# Install Rust programming language using rustup installer
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
apk add cargo     # Rust package manager (also installed by rustup)

# Remove unnecessary GNOME applications to streamline the installation:
apk del gnome-weather
apk del gnome-clocks
apk del gnome-contacts
apk del cheese       # Webcam application
apk del gnome-tour
apk del gnome-music
apk del gnome-calendar
apk del yelp         # Help browser
apk del simple-scan  # Scanning utility
apk del xsane        # Scanning utility (alternative)
apk del totem        # Video player
apk del snapshot     # Screenshot tool

# Reboot the system to apply all changes
reboot