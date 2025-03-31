#!/bin/bash

STATE_FILE="/tmp/script_state.txt"
LOG_FILE="/tmp/script_log.txt"

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

# Function to log messages
log_message() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

# Initial state
STATE=$(get_state)

# Checkpoint 1: Update and upgrade system
if [ "$STATE" == "START" ]; then
    log_message "Updating and upgrading system..."
    apk update && apk upgrade
    update_state "CHECKPOINT_1"
    log_message "Rebooting..."
    reboot
fi

# Checkpoint 2: Add repositories
if [ "$STATE" == "CHECKPOINT_1" ]; then
    log_message "Adding repositories..."
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
    log_message "Rebooting..."
    reboot
fi

# Checkpoint 3: Install Xorg and GNOME
if [ "$STATE" == "CHECKPOINT_2" ]; then
    log_message "Installing Xorg and GNOME..."
    setup-xorg-base
    apk add gnome gnome-apps-core gnome-apps-extra
    update_state "CHECKPOINT_3"
    log_message "Rebooting..."
    reboot
fi

# Checkpoint 4: Remove unwanted GNOME applications
if [ "$STATE" == "CHECKPOINT_3" ]; then
    log_message "Removing unwanted GNOME applications..."
    apk del gnome-calendar gnome-music gnome-camera gnome-tour gnome-videos gnome-help gnome-document-scanner
    update_state "CHECKPOINT_4"
    log_message "Rebooting..."
    reboot
fi

# Checkpoint 5: Start GDM and enable it to start on boot
if [ "$STATE" == "CHECKPOINT_4" ]; then
    log_message "Starting GDM and enabling it to start on boot..."
    rc-service gdm start
    rc-update add gdm
    update_state "CHECKPOINT_5"
    log_message "Rebooting..."
    reboot
fi

# Checkpoint 6: Install additional tools
if [ "$STATE" == "CHECKPOINT_5" ]; then
    log_message "Installing additional tools..."
    apk add bash bash-completion thunar-volman
    update_state "CHECKPOINT_6"
    log_message "Rebooting..."
    reboot
fi

# Checkpoint 7: Add a new user
if [ "$STATE" == "CHECKPOINT_6" ]; then
    log_message "Adding a new user..."
    adduser x -h /home/x
    update_state "CHECKPOINT_7"
    log_message "Rebooting..."
    reboot
fi

# Final state: Clean up
if [ "$STATE" == "CHECKPOINT_7" ]; then
    log_message "Cleaning up..."
    rm -f "$STATE_FILE"
    log_message "Script completed successfully."
fi

# Display the log file contents
if [ -f "$LOG_FILE" ]; then
    cat "$LOG_FILE"
fi
