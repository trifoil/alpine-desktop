#!/bin/bash

# Update and upgrade system
apk update && apk upgrade

# Add community repository if not already added
if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/latest-stable/community' /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories
fi

# Install Xorg and GNOME
apk add setup-xorg-base
apk add gnome gnome-apps-core gnome-apps-extra

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
