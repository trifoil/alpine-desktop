#!/bin/bash

# Update and upgrade system
apk update && apk upgrade

# Add main and community repositories if not already added
if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/latest-stable/main' /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main" >> /etc/apk/repositories
fi

if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/latest-stable/community' /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories
fi

# Update package lists
apk update && apk upgrade

# Install Xorg and GNOME
apk add xorg-server xf86-video-vesa xf86-input-libinput
apk add gnome gnome-apps-core

# Install necessary dependencies
apk add dbus elogind polkit bash bash-completion thunar-volman

# Enable and start required services
rc-update add dbus default
rc-service dbus start

rc-update add elogind default
rc-service elogind start

rc-update add gdm default
rc-service gdm start

# Ensure user exists and is in the correct groups
adduser x -h /home/x
adduser x video
adduser x audio
adduser x input
adduser x seat

# Final system update and reboot
apk update && apk upgrade
reboot
