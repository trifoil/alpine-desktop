#!/bin/bash

# Exit on error and print commands
set -e

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Try 'sudo sh install.sh'"
    exit 1
fi

# Create post-reboot cleanup script
cat > /etc/post-install-cleanup.sh << 'EOL'
#!/bin/bash

# Remove unwanted GNOME applications
apk del gnome-calendar gnome-music cheese gnome-tour totem yelp simple-scan

# Remove script itself and cleanup
rm -f /etc/post-install-cleanup.sh
rm -f /etc/local.d/post-install-cleanup.start

# Enable all services
rc-update add gdm default
rc-service gdm start

echo "Unwanted applications removed successfully!"
EOL

# Make the cleanup script executable
chmod +x /etc/post-install-cleanup.sh

# Create autostart entry for the cleanup script
cat > /etc/local.d/post-install-cleanup.start << 'EOL'
#!/bin/sh
/etc/post-install-cleanup.sh
EOL

chmod +x /etc/local.d/post-install-cleanup.start

# Update and upgrade system
echo "Updating system packages..."
apk update && apk upgrade

# Configure repositories
echo "Configuring repositories..."
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
echo "Updating package lists..."
apk update && apk upgrade

# Install Xorg and complete GNOME
echo "Installing Xorg and GNOME..."
setup-xorg-base
apk add gnome gnome-apps-core gnome-apps-extra

# Install additional required packages
echo "Installing additional packages..."
apk add bash bash-completion thunar-volman

# Create user if not exists
if ! id -u x >/dev/null 2>&1; then
    echo "Creating user 'x'..."
    adduser -D -h /home/x x
fi

# Enable services (but don't start gdm yet to prevent desktop loading before cleanup)
rc-update add gdm
rc-update add local default

# Final system update
echo "Performing final updates..."
apk update && apk upgrade

echo "Installation complete! The system will now reboot..."
echo "After reboot, the unwanted applications will be automatically removed."
reboot