#!/bin/bash

# Exit on error and print commands
set -ex

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Try 'sudo sh install.sh'"
    exit 1
fi

setup-desktop gnome

reboot