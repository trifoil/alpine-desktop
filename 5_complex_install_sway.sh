#!/bin/sh
set -e

##############################################
# 1) Overwrite /etc/apk/repositories to use Alpine v3.21
#    (Change "v3.21" to your version or "edge" as needed)
##############################################
cat <<EOF >/etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/v3.21/main
https://dl-cdn.alpinelinux.org/alpine/v3.21/community
EOF

##############################################
# 2) Update & Upgrade the System
##############################################
apk update
apk upgrade

##############################################
# 3) Install Sway and Required Packages
##############################################
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
  python3 \
  py3-pip \
  ttf-dejavu \
  \
  # Mesa graphics packages (covers Intel, Radeon, and a software fallback)
  mesa \
  mesa-egl \
  mesa-gbm \
  mesa-gl \
  mesa-egl-wayland \
  mesa-dri-intel \
  mesa-dri-radeon \
  mesa-dri-swrast

##############################################
# 4) Enable and Start Essential Services
##############################################
echo "Enabling and starting dbus..."
rc-update add dbus default
service dbus start

echo "Enabling and starting NetworkManager..."
rc-update add networkmanager default
service networkmanager start

##############################################
# 5) Configure Environment Variables for a Wayland Session
##############################################
{
  echo "export XDG_SESSION_TYPE=wayland"
  echo "export XDG_SESSION_DESKTOP=sway"
  echo "export XDG_CURRENT_DESKTOP=sway"
  echo "export GDK_BACKEND=wayland"
  echo "export QT_QPA_PLATFORM=wayland"
  echo "export MOZ_ENABLE_WAYLAND=1"
} >> /etc/profile

# Reload these variables in the current shell
. /etc/profile

##############################################
# 6) Download Default Configurations for Sway and Alacritty
##############################################
echo "Creating Sway configuration directory..."
mkdir -p ~/.config/sway
curl -o ~/.config/sway/config \
  https://raw.githubusercontent.com/swaywm/sway/master/config

echo "Creating Alacritty configuration directory..."
mkdir -p ~/.config/alacritty
curl -o ~/.config/alacritty/alacritty.yml \
  https://raw.githubusercontent.com/alacritty/alacritty/master/alacritty.yml

# Check that the configuration files exist
[ ! -f ~/.config/sway/config ] && { echo "Sway configuration file is missing!"; exit 1; }
[ ! -f ~/.config/alacritty/alacritty.yml ] && { echo "Alacritty configuration file is missing!"; exit 1; }

##############################################
# 7) Launch Sway
##############################################
echo "Launching Sway..."
exec sway

# If you prefer using startx and have a proper .xinitrc file,
# comment out the above `exec sway` and uncomment the lines below:
#
# startx
# [ $? -ne 0 ] && { echo "startx failed!"; exit 1; }
