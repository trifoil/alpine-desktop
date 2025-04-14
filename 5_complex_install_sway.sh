#!/bin/sh
set -e

##############################################
# 1) Overwrite /etc/apk/repositories with v3.21 repos
#    (Replace v3.21 with "edge" or your actual version if needed)
##############################################
cat <<EOF >/etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/v3.21/main
https://dl-cdn.alpinelinux.org/alpine/v3.21/community
EOF

##############################################
# 2) Update and upgrade
##############################################
apk update
apk upgrade

##############################################
# 3) Install Sway + dependencies
#    using updated package names
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
  \
  # Noto fonts are renamed to "fonts-noto", "fonts-noto-cjk", etc.
  fonts-noto \
  fonts-noto-cjk \
  fonts-noto-emoji \
  \
  # For Mesa / graphics, Alpine 3.21 no longer has a meta-package "mesa-dri".
  # You must install Mesa and DRI drivers explicitly:
  mesa \
  mesa-egl \
  mesa-gbm \
  mesa-gl \
  mesa-egl-wayland \
  mesa-dri-intel \
  mesa-dri-radeon \
  mesa-dri-swrast

##############################################
# 4) Enable and start dbus + NetworkManager
##############################################
rc-update add dbus default
service dbus start

rc-update add networkmanager default
service networkmanager start

##############################################
# 5) Configure environment variables
##############################################
{
  echo "export XDG_SESSION_TYPE=wayland"
  echo "export XDG_SESSION_DESKTOP=sway"
  echo "export XDG_CURRENT_DESKTOP=sway"
  echo "export GDK_BACKEND=wayland"
  echo "export QT_QPA_PLATFORM=wayland"
  echo "export MOZ_ENABLE_WAYLAND=1"
} >> /etc/profile

# Reload them for the current shell
. /etc/profile

##############################################
# 6) Create default configs for Sway & Alacritty
##############################################
mkdir -p ~/.config/sway
curl -o ~/.config/sway/config \
  https://raw.githubusercontent.com/swaywm/sway/master/config

mkdir -p ~/.config/alacritty
curl -o ~/.config/alacritty/alacritty.yml \
  https://raw.githubusercontent.com/alacritty/alacritty/master/alacritty.yml

# Verify they exist
[ ! -f ~/.config/sway/config ] && { echo "Missing Sway config"; exit 1; }
[ ! -f ~/.config/alacritty/alacritty.yml ] && { echo "Missing Alacritty config"; exit 1; }

##############################################
# 7) (Optionally) Launch Sway directly
##############################################
exec sway

# If you prefer startx (with .xinitrc that calls 'exec sway'), do:
# startx
