#!/bin/sh

# DWM Installation Script for Alpine Linux
# Run as root

# Enable community repository if not already enabled
if ! grep -q '^http.*/community' /etc/apk/repositories; then
    echo "Enabling community repository..."
    echo "https://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/community" >> /etc/apk/repositories
fi

# Update package index
echo "Updating package list..."
apk update

# Install Xorg base system
echo "Installing Xorg base system..."
setup-xorg-base

# Install essential dependencies
echo "Installing essential dependencies..."
apk add \
    git make gcc musl-dev \
    libx11-dev libxft-dev libxinerama-dev \
    ncurses dbus dbus-x11 \
    pciutils udev-init-scripts

# Setup eudev (device manager)
echo "Setting up eudev..."
setup-devd udev

# Start and enable dbus
echo "Configuring dbus..."
rc-update add dbus
rc-service dbus start

# Install optional packages (for better Firefox experience)
echo "Installing optional packages..."
apk add \
    firefox-esr \
    adwaita-gtk2-theme \
    adwaita-icon-theme \
    font-dejavu

# Install suckless tools from source
echo "Installing suckless tools from source..."

# Create build directory
BUILD_DIR=/tmp/suckless-build
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Install dwm
echo "Installing dwm..."
git clone https://git.suckless.org/dwm
cd dwm
make clean install
cd ..

# Install dmenu
echo "Installing dmenu..."
git clone https://git.suckless.org/dmenu
cd dmenu
make clean install
cd ..

# Install st (simple terminal)
echo "Installing st..."
git clone https://git.suckless.org/st
cd st
make clean install
cd ..

# Clean up build directory
echo "Cleaning up..."
rm -rf "$BUILD_DIR"

# Configure user environment
echo "Configuring user environment..."

# Create .xinitrc if it doesn't exist
if [ ! -f ~/.xinitrc ]; then
    echo "Creating ~/.xinitrc..."
    echo 'exec dwm' > ~/.xinitrc
fi

# Create .profile with conditional startx
if [ ! -f ~/.profile ]; then
    echo "Creating ~/.profile..."
    cat > ~/.profile << 'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
EOF
fi

# Set permissions
chmod 755 ~/.xinitrc ~/.profile

echo ""
echo "Installation complete!"
echo "To start dwm:"
echo "1. Log out and log back in"
echo "2. Or run 'startx' manually"
echo ""
echo "Note: Firefox can be launched with Alt+P (dmenu) then typing 'firefox'"