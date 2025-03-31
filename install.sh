#!/bin/bash

# Update and upgrade
apk update && apk upgrade

# Add community repo (if not already added)
if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/latest-stable/community' /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories
fi

# Prompt to create a new user (skip if already exists)
read -p "Do you want to create a new user for GNOME? (y/n): " create_user
if [[ $create_user =~ ^[Yy]$ ]]; then
    read -p "Enter username: " username
    if id "$username" &>/dev/null; then
        echo "User $username already exists. Skipping creation."
    else
        # Create user with a home directory and add to necessary groups
        adduser -D "$username" -G wheel,audio,video,netdev
        passwd "$username"  # Prompt to set password
        echo "User $username created successfully."
    fi
fi

# Install only the core GNOME components (no meta-package)
apk add --no-cache \
    gdm \
    gnome-shell \
    gnome-session \
    gnome-terminal \
    nautilus \
    gnome-control-center \
    gnome-backgrounds \
    gnome-menus \
    gnome-themes-extra \
    gnome-keyring \
    gnome-disk-utility \
    gnome-system-monitor \
    gnome-screenshot \
    gnome-tweaks \
    gnome-software

# Optional: Install additional useful apps (customize as needed)
apk add --no-cache \
    eog \
    evince \
    file-roller \
    gedit \
    seahorse

# Explicitly block unwanted apps to prevent future installation
apk add --no-cache --virtual .unwanted-gnome-apps \
    gnome-weather \
    gnome-calendar \
    gnome-music \
    gnome-camera \
    gnome-tour \
    gnome-videos \
    gnome-user-docs \
    gnome-documents \
    simple-scan

# Enable GDM (GNOME Display Manager) on boot
rc-update add gdm default

echo "GNOME installed successfully without unwanted apps. Rebooting..."
reboot