#!/bin/bash

# Exit on error and print commands
set -ex

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Try 'sudo sh install.sh'"
    exit 1
fi

# Create post-reboot cleanup script
cat > /etc/post-install-cleanup.sh << 'EOL'
#!/bin/sh

# Remove unwanted GNOME applications
apk del gnome-calendar gnome-music cheese gnome-tour totem yelp simple-scan

# Clean up
rm -f /etc/post-install-cleanup.sh
rm -f /etc/rc.local

# Enable GDM if not already enabled
if ! rc-status default | grep -q gdm; then
    rc-update add gdm default
    rc-service gdm start
fi

echo "Unwanted applications removed successfully!" > /var/log/post-install-cleanup.log
EOL

# Make the cleanup script executable
chmod +x /etc/post-install-cleanup.sh

# Create rc.local to run cleanup on boot
cat > /etc/rc.local << 'EOL'
#!/bin/sh

# Run cleanup script
/etc/post-install-cleanup.sh

exit 0
EOL

chmod +x /etc/rc.local

# Enable rc.local service
rc-update add local default

# Update and upgrade system
echo "Updating system packages..."
apk update && apk upgrade

# Configure repositories
echo "Configuring repositories..."
REPO_FILE="/etc/apk/repositories"
for repo in main community testing; do
    if ! grep -q "^http://dl-cdn.alpinelinux.org/alpine/edge/$repo" "$REPO_FILE"; then
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/$repo" >> "$REPO_FILE"
    fi
done

# Update package lists
echo "Updating package lists..."
apk update && apk upgrade

# Install Xorg and complete GNOME
echo "Installing Xorg and GNOME..."
setup-xorg-base
apk add gnome gnome-apps-core 

# Install additional required packages
echo "Installing additional packages..."
apk add bash bash-completion 

# Create user if not exists
if ! id -u x >/dev/null 2>&1; then
    echo "Creating user 'x'..."
    adduser -D -h /home/x x
    echo "x:password" | chpasswd  # Set password to 'password' - CHANGE THIS!
fi

# Temporarily disable gdm from starting automatically
rc-update del gdm default 2>/dev/null || true

# Final system update
echo "Performing final updates..."
apk update && apk upgrade

echo "Installation complete! The system will now reboot..."
echo "After reboot, the unwanted applications will be automatically removed."
echo "You can check /var/log/post-install-cleanup.log to verify the cleanup."

reboot