#!/bin/bash

# Exit on error and print commands
set -ex

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Try 'sudo sh install.sh'"
    exit 1
fi

echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

apk update && apk upgrade

setup-desktop gnome

apk add vscodium
apk add curl nano fastfetch
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
apk add cargo
apk del gnome-weather
apk del gnome-clocks
apk del gnome-contacts
apk del cheese  # GNOME Camera is usually packaged as 'cheese' in Alpine
apk del gnome-tour
apk del gnome-music
apk del gnome-calendar
apk del simple-scan  # For the GNOME scanner application
apk del xsane  # Alternative scanner application



#reboot
