#!/bin/bash

# Update and upgrade
apk update && apk upgrade

# Add community repo (if not already added)
echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories

# Install GNOME
setup-desktop gnome

# Remove useless stuff
apk del gnome-weather gnome-calendar gnome-music gnome-camera gnome-tour gnome-videos gnome-user-docs gnome-documents simple-scan
