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

#reboot
