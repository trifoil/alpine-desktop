#!/bin/sh
set -e

#############################
# Helper Functions
#############################

# Function to log messages
log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $*"
}

# Check if a package is available in the repo via apk search.
# This function uses a regular expression to match the entire package name.
check_pkg_availability() {
  pkg="$1"
  # The caret (^) and dollar ($) ensure an exact name match.
  if apk search -v "^${pkg}\$" | grep -q "^${pkg}"; then
    return 0
  else
    return 1
  fi
}

# Check all required packages.
# Returns 0 if all packages are found; otherwise returns 1.
check_all_packages() {
  missing_pkgs=""
  for pkg in $REQUIRED_PKGS; do
    if check_pkg_availability "$pkg"; then
      log "Found package: $pkg"
    else
      log "Missing package: $pkg"
      missing_pkgs="$missing_pkgs $pkg"
    fi
  done

  if [ -n "$missing_pkgs" ]; then
    log "The following packages are missing:$missing_pkgs"
    return 1
  else
    return 0
  fi
}

# Set repositories to stable for a given Alpine version
set_repos_stable() {
  # Extract ALPINE_VERSION from /etc/alpine-release (format: "3.21.4")
  ALPINE_VERSION=$(cut -d. -f1,2 /etc/alpine-release)
  log "Setting repositories to Alpine stable v$ALPINE_VERSION"
  cat <<EOF >/etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main
https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community
EOF
}

# Set repositories to edge channels
set_repos_edge() {
  log "Switching repositories to Alpine edge (rolling release)"
  cat <<EOF >/etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF
}

# Update system package index and upgrade system
update_system() {
  log "Updating package list..."
  apk update
  log "Upgrading installed packages..."
  apk upgrade
}

#############################
# Main Script
#############################

# 1. Determine Architecture and Alpine Version
ARCH=$(uname -m)
log "Detected architecture: $ARCH"
if [ -f /etc/alpine-release ]; then
  ALPINE_FULL_VERSION=$(cat /etc/alpine-release)
  ALPINE_VERSION=$(echo "$ALPINE_FULL_VERSION" | cut -d. -f1,2)
  log "Detected Alpine version: $ALPINE_FULL_VERSION (using v${ALPINE_VERSION} for repos)"
else
  log "Error: /etc/alpine-release not found. Exiting."
  exit 1
fi

# 2. Define the required packages (Sway, dependencies, fonts, and Mesa subpackages)
REQUIRED_PKGS="
sway
swaybar
swaybg
alacritty
wayland
weston
wayland-protocols
wlroots
dbus
xwayland
i3lock
networkmanager
networkmanager-openvpn
sudo
terminus-font
fontconfig
python3
py3-pip
ttf-dejavu
mesa-egl
mesa-gl
mesa-gbm
mesa-egl-wayland
mesa-dri-intel
mesa-dri-radeon
mesa-dri-swrast
"

# 3. Set repositories to stable and update system
set_repos_stable
update_system

# 4. Check availability of all required packages on stable
if check_all_packages; then
  log "All required packages found in the stable repositories."
else
  log "Not all packages are available in stable. Attempting to switch to edge repositories."
  set_repos_edge
  update_system
  if check_all_packages; then
    log "All required packages are now available from edge repositories."
  else
    log "Error: Even after switching to edge repositories, some packages are missing. Aborting installation."
    exit 1
  fi
fi

# 5. Proceed with installation of all required packages
log "Installing all required packages..."
apk add --no-cache $REQUIRED_PKGS

# 6. Enable and Start Essential Services (dbus and NetworkManager)
log "Enabling and starting dbus..."
rc-update add dbus default
service dbus start

log "Enabling and starting NetworkManager..."
rc-update add networkmanager default
service networkmanager start

# 7. Configure Environment Variables for Wayland/Sway session
log "Configuring environment variables for Wayland..."
cat <<EOF >> /etc/profile
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=sway
export XDG_CURRENT_DESKTOP=sway
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export MOZ_ENABLE_WAYLAND=1
EOF
. /etc/profile

# 8. Create configuration directories and download default configs for Sway and Alacritty
log "Creating Sway configuration directory and downloading default config..."
mkdir -p ~/.config/sway
curl -fsSL -o ~/.config/sway/config https://raw.githubusercontent.com/swaywm/sway/master/config

log "Creating Alacritty configuration directory and downloading default config..."
mkdir -p ~/.config/alacritty
curl -fsSL -o ~/.config/alacritty/alacritty.yml https://raw.githubusercontent.com/alacritty/alacritty/master/alacritty.yml

# Verify that configuration files exist
if [ ! -f ~/.config/sway/config ]; then
  log "Error: Sway configuration file not found. Exiting."
  exit 1
fi
if [ ! -f ~/.config/alacritty/alacritty.yml ]; then
  log "Error: Alacritty configuration file not found. Exiting."
  exit 1
fi

# 9. Launch Sway
log "Launching Sway..."
exec sway
