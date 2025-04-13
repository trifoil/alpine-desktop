#!/bin/sh

# Update repositories and install dependencies
echo "Updating repositories and installing dependencies..."
apk update
apk upgrade
apk add --no-cache \
  sway \
  alacritty \
  wayland \
  weston \
  wayland-protocols \
  wlroots \
  dbus \
  xwayland \
  i3lock \
  networkmanager \
  networkmanager-openvpn \
  sudo \
  terminus-font \
  fontconfig \
  noto-fonts \
  noto-fonts-cjk \
  noto-fonts-emoji \
  python3 \
  py3-pip \
  i3bar \
  mesa-dri

# Install swaybar and swaybg
apk add --no-cache swaybar swaybg

# Enable dbus
echo "Enabling and starting dbus..."
rc-update add dbus
service dbus start

# Enable NetworkManager
echo "Enabling NetworkManager..."
rc-update add networkmanager
service networkmanager start

# Configure environment variables for Sway
echo "Setting environment variables..."
echo "export XDG_SESSION_TYPE=wayland" >> /etc/profile
echo "export XDG_SESSION_DESKTOP=sway" >> /etc/profile
echo "export XDG_CURRENT_DESKTOP=sway" >> /etc/profile
echo "export GDK_BACKEND=wayland" >> /etc/profile
echo "export QT_QPA_PLATFORM=wayland" >> /etc/profile
echo "export MOZ_ENABLE_WAYLAND=1" >> /etc/profile
source /etc/profile

# Create sway config file
echo "Creating default sway config..."
mkdir -p ~/.config/sway
curl -o ~/.config/sway/config https://raw.githubusercontent.com/swaywm/sway/master/config

# Set up alacritty config
echo "Setting up Alacritty config..."
mkdir -p ~/.config/alacritty
curl -o ~/.config/alacritty/alacritty.yml https://raw.githubusercontent.com/alacritty/alacritty/master/alacritty.yml

# Enable and start Sway
echo "Starting Sway..."
startx

# Print completion
echo "Sway installation and configuration complete!"
