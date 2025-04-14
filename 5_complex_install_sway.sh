#!/bin/sh
set -e

##############################################
# 1) Overwrite /etc/apk/repositories with Alpine v3.21
#    (Remove this block if your repos are already correct)
##############################################
cat <<EOF >/etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/v3.21/main
https://dl-cdn.alpinelinux.org/alpine/v3.21/community
EOF

##############################################
# 2) Update & Upgrade
##############################################
apk update
apk upgrade

##############################################
# 3) Install Sway + Subpackages for Mesa
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
  # Instead of "mesa", install subpackages
  mesa-egl \
  mesa-gl \
  mesa-gbm \
  mesa-egl-wayland \
  mesa-dri-intel \
  mesa-dri-radeon \
  mesa-dri-swrast

##############################################
# 4) Enable and Start Services
##############################################
rc-update add dbus default
service dbus start

rc-update add networkmanager default
service networkmanager start

##############################################
# 5) Configure Wayland Environment Variables
##############################################
{
  echo "export XDG_SESSION_TYPE=wayland"
  echo "export XDG_SESSION_DESKTOP=sway"
  echo "export XDG_CURRENT_DESKTOP=sway"
  echo "export GDK_BACKEND=wayland"
  echo "export QT_QPA_PLATFORM=wayland"
  echo "export MOZ_ENABLE_WAYLAND=1"
} >> /etc/profile
. /etc/profile

##############################################
# 6) Create Default Configs for Sway & Alacritty
##############################################
mkdir -p ~/.config/sway
curl -o ~/.config/sway/config \
  https://raw.githubusercontent.com/swaywm/sway/master/config

mkdir -p ~/.config/alacritty
curl -o ~/.config/alacritty/alacritty.yml \
  https://raw.githubusercontent.com/alacritty/alacritty/master/alacritty.yml

[ ! -f ~/.config/sway/config ] && { echo "Missing Sway config!"; exit 1; }
[ ! -f ~/.config/alacritty/alacritty.yml ] && { echo "Missing Alacritty config!"; exit 1; }

##############################################
# 7) Launch Sway
##############################################
exec sway
