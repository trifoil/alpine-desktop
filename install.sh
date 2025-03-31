#!/bin/bash

# Update and upgrade
apk update && apk upgrade

# Add community repo (if not already added)
if ! grep -q '^http://dl-cdn.alpinelinux.org/alpine/latest-stable/community' /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories
fi

# Prompt to create a new user for GNOME
read -p "Do you want to create a new user for GNOME? (y/n): " create_user
if [[ $create_user =~ ^[Yy]$ ]]; then
    read -p "Enter username: " username
    if id "$username" &>/dev/null; then
        echo "User $username already exists. Skipping creation."
    else
        # Create user with home dir and add to required groups
        adduser -D "$username" -G wheel,audio,video,netdev
        passwd "$username"  # Prompt to set password
        echo "User $username created successfully."
    fi
fi

# Install core GNOME components (no meta-package)
apk add --no-cache \
    gdm \
    gnome-shell \
    gnome-session \
    gnome-terminal \
    nautilus \
    gnome-control-center \
    gnome-backgrounds \
    gnome-menus \
    gnome-themes-extra \
    gnome-keyring \
    gnome-disk-utility \
    gnome-system-monitor \
    gnome-screenshot \
    gnome-tweaks \
    gnome-software

# Install required background services
apk add --no-cache dbus elogind polkit
rc-update add dbus
rc-update add elogind
rc-service dbus start
rc-service elogind start

# Create GDM OpenRC service if missing
if [ ! -f /etc/init.d/gdm ]; then
    cat <<EOF > /etc/init.d/gdm
#!/sbin/openrc-run
command="/usr/bin/gdm"
command_background=true
pidfile="/run/gdm.pid"
depend() {
    need dbus elogind
}
EOF
    chmod +x /etc/init.d/gdm
fi

# Block unwanted apps
apk add --no-cache --virtual .unwanted-gnome-apps \
    gnome-weather \
    gnome-calendar \
    gnome-music \
    gnome-camera \
    gnome-tour \
    gnome-videos \
    gnome-user-docs \
    gnome-documents \
    simple-scan

# Enable and start GDM
rc-update add gdm default
rc-service gdm start

echo "GNOME installed successfully. Rebooting in 5 seconds..."
sleep 5
reboot