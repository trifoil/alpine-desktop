#!/bin/sh
set -e

##############################################
# 1) Overwrite /etc/apk/repositories to use Alpine v3.21
#    (Change v3.21 to "edge" or your version if needed)
##############################################
cat <<EOF >/etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/v3.21/main
https://dl-cdn.alpinelinux.org/alpine/v3.21/community
EOF

##############################################
# 2) Update & upgrade
##############################################
apk update
apk upgrade

##############################################
# 3) Install Sway + dependencies
#    NOTE: We revert to the older package naming
#    for Noto fonts & break down Mesa drivers.
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
  # Revert to older naming for Noto fonts:
  noto-fonts \
  noto-fonts-cjk \
  noto-fonts-emoji \
  \
  # Mesa drivers: "mesa-dri" is split into separate packages
  # in newer Alpine. Install them all to cover Intel, AMD, software fallback.
  mesa \
  mesa-egl \
  mesa-gbm \
  mesa-gl \
  mesa-egl-wayland \
  mesa-dri-intel \
  mesa-dri-radeon \
  mesa-dri-swrast

##############################################
# 4) Enable and start D-Bus and NetworkManager
##############################################
rc-update add dbus default
service dbus start

rc-update add networkmanager default
service networkmanager start

##############################################
# 5) Configure Wayland environment variables
##############################################
{
  echo "export XDG_SESSION_TYPE=wayland"
  echo "export XDG_SESSION_DESKTOP=sway"
  echo "export XDG_CURRENT_DESKTOP=sway"
  echo "export GDK_BACKEND=wayland"
  echo "export QT_QPA_PLATFORM=wayland"
  echo "export MOZ_ENABLE_WAYLAND=1"
} >> /etc/profile

# Reload environment variables now
. /etc/profile

##############################################
# 6) Create default configuration for Sway & Alacritty
##############################################
mkdir -p ~/.config/sway
curl -o ~/.config/sway/config \
  https://raw.githubusercontent.com/swaywm/sway/master/config

mkdir -p ~/.config/alacritty
curl -o ~/.config/alacritty/alacritty.yml \
  https://raw.githubusercontent.com/alacritty/alacritty/master/alacritty.yml

[ ! -f ~/.config/sway/config ] && { echo "Sway config missing!"; exit 1; }
[ ! -f ~/.config/alacritty/alacritty.yml ] && { echo "Alacritty config missing!"; exit 1; }

##############################################
# 7) Start Sway (directly or via startx)
##############################################
exec sway

# If you prefer startx and have an .xinitrc with 'exec sway', do this:
# startx
