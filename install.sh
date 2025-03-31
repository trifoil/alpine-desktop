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

# Install Xorg and GNOME core without unwanted applications
setup-xorg-base 

# Install GNOME core without specific applications
apk add gnome --no-cache \
    --exclude gnome-calendar \
    --exclude gnome-music \
    --exclude cheese \
    --exclude gnome-tour \
    --exclude totem \
    --exclude yelp \
    --exclude simple-scan

# Install additional GNOME components carefully
apk add gnome-apps-core --no-cache \
    --exclude gnome-calendar \
    --exclude gnome-music \
    --exclude cheese \
    --exclude gnome-tour \
    --exclude totem \
    --exclude yelp \
    --exclude simple-scan

apk add gnome-apps-extra --no-cache \
    --exclude gnome-calendar \
    --exclude gnome-music \
    --exclude cheese \
    --exclude gnome-tour \
    --exclude totem \
    --exclude yelp \
    --exclude simple-scan

# Start and enable GDM
rc-service gdm start
rc-update add gdm

# Install additional required packages
apk add bash bash-completion thunar-volman

# Update again
apk update

# Create user
adduser x -h /home/x

# Final system update and reboot
apk update && apk upgrade
reboot