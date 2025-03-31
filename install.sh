#!/bin/bash

# Update and upgrade
apk update && apk upgrade

# Add community repo (if not already added)
if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/latest-stable/community' /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories
fi

setup-xorg-base

apk add gnome gnome-apps-core gnome-apps-extra

rc-service gdm start

rc-update add gdm

apk add bash bash-completion

apk add thunar-volman

apk update && apk upgrade

adduser x -h /home/x

reboot

