#!/bin/sh
set -e

##############################################
# Hard-code Alpine repositories to v3.21
# (Adjust if you want to use a different version)
##############################################
cat <<EOF >/etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/v3.21/main
https://dl-cdn.alpinelinux.org/alpine/v3.21/community
EOF

##############################################
# Function to check if the previous command succeeded
##############################################
check_command() {
  if [ $? -ne 0 ]; then
    echo "Error during command execution: $1" >&2
    exit 1
  fi
}

##############################################
# Update repositories and upgrade existing packages
##############################################
echo "Updating repositories and upgrading system..."
apk update
check_command "apk update"

apk upgrade
check_command "apk upgrade"

##############################################
# Install Sway and other dependencies
##############################################
echo "Installing Sway and related packages..."
apk add --no-cache \
  sway \
  swaybar \
  swaybg \
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
  mesa-dri
check_command "apk add Sway dependencies"

##############################################
# Enable and start dbus and NetworkManager
##############################################
echo "Enabling dbus and NetworkManager..."
rc-update add dbus default
check_command "rc-update add dbus"
service dbus start
check_command "service dbus start"

rc-update add networkmanager default
check_command "rc-update add networkmanager"
service networkmanager start
check_command "service networkmanager start"

##############################################
# Configure environment variables for Wayland
##############################################
echo "Configuring environment variables..."
{
  echo "export XDG_SESSION_TYPE=wayland"
  echo "export XDG_SESSION_DESKTOP=sway"
  echo "export XDG_CURRENT_DESKTOP=sway"
  echo "export GDK_BACKEND=wayland"
  echo "export QT_QPA_PLATFORM=wayland"
  echo "export MOZ_ENABLE_WAYLAND=1"
} >> /etc/profile
check_command "Updating /etc/profile with environment variables"

# Reload environment variables for this session
source /etc/profile

##############################################
# Create default config files for Sway & Alacritty
##############################################
echo "Creating default Sway configuration..."
mkdir -p ~/.config/sway
check_command "mkdir ~/.config/sway"

curl -o ~/.config/sway/config \
  https://raw.githubusercontent.com/swaywm/sway/master/config
check_command "Downloading default Sway config"

echo "Creating default Alacritty configuration..."
mkdir -p ~/.config/alacritty
check_command "mkdir ~/.config/alacritty"

curl -o ~/.config/alacritty/alacritty.yml \
  https://raw.githubusercontent.com/alacritty/alacritty/master/alacritty.yml
check_command "Downloading default Alacritty config"

# Ensure config files exist
if [ ! -f ~/.config/sway/config ]; then
  echo "Sway configuration file missing. Check your setup." >&2
  exit 1
fi

if [ ! -f ~/.config/alacritty/alacritty.yml ]; then
  echo "Alacritty config file missing. Check your setup." >&2
  exit 1
fi

##############################################
# Launch Sway
##############################################
echo "Starting Sway session..."

# Option 1: Directly launch Sway (common for Wayland)
exec sway

# Option 2 (commented out): Using startx if you have a .xinitrc with 'exec sway'
# startx
# check_command "startx"

echo "Sway installation and setup complete!"
