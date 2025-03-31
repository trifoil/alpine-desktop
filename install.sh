#!/bin/bash

# Update and upgrade
apk update && apk upgrade

# Add community repo (if not already added)
if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/latest-stable/community' /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories
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

echo "GNOME installed successfully without unwanted apps."

reboot