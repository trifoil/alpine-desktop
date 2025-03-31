#!/bin/bash

# Update and upgrade system
apk update && apk upgrade

# Add main and community repositories if not already added
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
apk update && apk upgrade

# Install Xorg and GNOME
setup-xorg-base 
apk add gnome
apk add gnome-apps-core
apk add gnome-apps-extra

rc-service gdm start
rc-update add gdm
apk add bash
apk add bash-completion
apk add thunar-volman
apk update

adduser x -h /home/x


# Final system update and reboot
apk update && apk upgrade
reboot
