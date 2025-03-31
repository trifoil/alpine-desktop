#!/bin/bash

# Update and upgrade
apk update && apk upgrade

# Add community repo (if not already added)
if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/latest-stable/community' /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories
fi

# Install GNOME desktop (core components only)
setup-desktop gnome

# Now force-remove the unwanted applications
apk del \
    gnome-weather \
    gnome-calendar \
    gnome-music \
    gnome-camera \
    gnome-tour \
    gnome-videos \
    gnome-user-docs \
    gnome-documents \
    simple-scan

# Optional: Mark these packages as explicitly unwanted to prevent reinstallation
apk add --virtual .unwanted-gnome-apps \
    gnome-weather \
    gnome-calendar \
    gnome-music \
    gnome-camera \
    gnome-tour \
    gnome-videos \
    gnome-user-docs \
    gnome-documents \
    simple-scan