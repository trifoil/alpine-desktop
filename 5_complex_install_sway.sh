#!/bin/sh
set -e  # Exit immediately if a command exits with a non-zero status

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
# Ensure the Alpine community repository is enabled
##############################################
if ! grep -q "community" /etc/apk/repositories; then
  echo "Community repository not found. Adding it..."

  # Determine Alpine version if possible
  if [ -f /etc/alpine-release ]; then
    ALPINE_VERSION=$(cut -d. -f1,2 /etc/alpine-release)
  else
    echo "Alpine release file not found. Using default 'latest' tag for repository URL." >&2
    ALPINE_VERSION="latest"
  fi

  # Try to base the community repo URL on an existing main repo line
  MAIN_REPO=$(grep "/main" /etc/apk/repositories | head -n1)
  if [ -n "$MAIN_REPO" ]; then
    # Replace '/main' with '/community' in the URL
    COMMUNITY_REPO=$(echo "$MAIN_REPO" | sed 's/\/main/\/community/')
  else
    # Fallback URL if no main repo is detected
    COMMUNITY_REPO="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community"
  fi

  # Append the community repository to the repositories file
  echo "$COMMUNITY_REPO" >> /etc/apk/repositories
  check_command "Adding community repository"

  echo "Added community repository: $COMMUNITY_REPO"
fi

##############################################
# Update repositories and installed packages
##############################################
echo "Updating repositories and upgrading packages..."
apk update
check_command "apk update"

apk upgrade
check_command "apk upgrade"

##############################################
# Install required packages from main and community repositories
##############################################
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
  mesa-dri
check_command "apk add dependencies"

# Install additional Sway utilities
apk add --no-cache swaybar swaybg
check_command "apk add swaybar and swaybg"

##############################################
# Enable and start essential services
##############################################
echo "Enabling and starting dbus..."
rc-update add dbus default
check_command "rc-update add dbus"

service dbus start
check_command "service dbus start"

echo "Enabling and starting NetworkManager..."
rc-update add networkmanager default
check_command "rc-update add networkmanager"

service networkmanager start
check_command "service networkmanager start"

##############################################
# Configure environment variables for Wayland/Sway sessions
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

# Reload environment variables for current session
source /etc/profile

##############################################
# Create default configuration files for Sway and Alacritty
##############################################
echo "Creating default Sway configuration..."
mkdir -p ~/.config/sway
check_command "Creating ~/.config/sway directory"

curl -o ~/.config/sway/config https://raw.githubusercontent.com/swaywm/sway/master/config
check_command "Downloading default Sway configuration"

echo "Creating default Alacritty configuration..."
mkdir -p ~/.config/alacritty
check_command "Creating ~/.config/alacritty directory"

curl -o ~/.config/alacritty/alacritty.yml https://raw.githubusercontent.com/alacritty/alacritty/master/alacritty.yml
check_command "Downloading default Alacritty configuration"

# Verify that configuration files exist
if [ ! -f ~/.config/sway/config ]; then
  echo "Sway configuration file missing. Please verify your setup." >&2
  exit 1
fi

if [ ! -f ~/.config/alacritty/alacritty.yml ]; then
  echo "Alacritty configuration file missing. Please verify your setup." >&2
  exit 1
fi

##############################################
# Launch Sway
##############################################
echo "Starting Sway session..."

# Choose one of the following options to launch Sway:
#
# Option 1: Using startx (Make sure you have an appropriate .xinitrc with 'exec sway')
# startx
# check_command "startx"
#
# Option 2: Directly executing Sway (commonly used in Wayland sessions)
exec sway

# If sway exits and you're still in the script, the following line will not be reached.
echo "Installation and configuration of Sway completed successfully!"
