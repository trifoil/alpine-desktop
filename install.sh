#!/bin/bash

STATE_FILE="/tmp/script_state.txt"

# Function to update the state file
update_state() {
    echo "$1" > "$STATE_FILE"
}

# Function to get the current state
get_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "START"
    fi
}

# Initial state
STATE=$(get_state)

# Checkpoint 1: Update and upgrade system
if [ "$STATE" == "START" ]; then
    apk update && apk upgrade
    update_state "CHECKPOINT_1"
    reboot
fi

# Checkpoint 2: Add repositories
if [ "$STATE" == "CHECKPOINT_1" ]; then
    if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/edge/main' /etc/apk/repositories; then
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
    fi
    if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/edge/community' /etc/apk/repositories; then
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
    fi
    if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/edge/testing' /etc/apk/repositories; then
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
    fi
    update_state "CHECKPOINT_2"
    reboot
fi

# Checkpoint 3: Install Xorg and GNOME
if [ "$STATE" == "CHECKPOINT_2" ]; then
    setup-xorg-base
    apk add gnome gnome-apps-core gnome-apps-extra
    update_state "CHECKPOINT_3"
    reboot
fi

# Checkpoint 4: Remove unwanted GNOME applications
if [ "$STATE" == "CHECKPOINT_3" ]; then
    apk del gnome-calendar gnome-music gnome-camera gnome-tour gnome-videos gnome-help gnome-document-scanner
    update_state "CHECKPOINT_4"
    reboot
fi

# Checkpoint 5: Start GDM and enable it to start on boot
if [ "$STATE" == "CHECKPOINT_4" ]; then
    rc-service gdm start
    rc-update add gdm
    update_state "CHECKPOINT_5"
    reboot
fi

# Checkpoint 6: Install additional tools
if [ "$STATE" == "CHECKPOINT_5" ]; then
    apk add bash bash-completion thunar-volman
    update_state "CHECKPOINT_6"
    reboot
fi

# Checkpoint 7: Add a new user
if [ "$STATE" == "CHECKPOINT_6" ]; then
    adduser x -h /home/x
    update_state "CHECKPOINT_7"
    reboot
fi

# Final state: Clean up
if [ "$STATE" == "CHECKPOINT_7" ]; then
    rm -f "$STATE_FILE"
    echo "Script completed successfully."
fi
