#!/bin/bash

# Exit on error and print commands
set -ex

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Try 'doas sh install.sh'"
    exit 1
fi

# Update and upgrade system
echo "Updating system packages..."
apk update && apk upgrade

# Configure repositories
echo "Configuring repositories..."
if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/edge/main' /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
fi

if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/edge/community' /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
fi

if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/edge/testing' /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
fi

# Update package lists
echo "Updating package lists..."
apk update && apk upgrade

# Install Xorg and complete GNOME
echo "Installing Xorg and GNOME..."
setup-xorg-base
apk add gnome gnome-apps-core

# Install additional required packages
echo "Installing additional packages..."
apk add bash bash-completion curl gcc musl-dev doas

# Configure doas if not already configured
if [ ! -f /etc/doas.conf ]; then
    echo "permit persist keepenv :wheel" > /etc/doas.conf
    chmod 0400 /etc/doas.conf
fi

# Create user if not exists
if ! id -u x >/dev/null 2>&1; then
    echo "Creating user 'x'..."
    adduser -D -h /home/x x -G wheel
fi

# Install Rust via rustup as the target user
echo "Installing Rust..."
if ! runuser -u x -- command -v rustup &> /dev/null; then
    # Download and run rustup installer as the target user
    runuser -u x -- curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | runuser -u x -- sh -s -- -y
    
    # Add cargo to user's PATH
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /home/x/.bashrc
    
    # Install basic components
    runuser -u x -- sh -c '. /home/x/.cargo/env && rustup component add rust-src rust-docs'
fi

# Enable GDM
echo "Enabling GDM service..."
rc-update add gdm default

# Final system update
echo "Performing final updates..."
apk update && apk upgrade

echo "Installation complete!"
echo "Rust and cargo have been installed for user 'x'"
echo "You can start the graphical environment by running:"
echo "rc-service gdm start"