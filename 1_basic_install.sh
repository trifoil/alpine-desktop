#!/bin/bash

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Try 'sudo sh $0'"
    exit 1
fi

# Add Alpine's edge/testing repo
echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Update & upgrade
apk update && apk upgrade

# Fix UTF-8 locale for btop
apk add musl-locales
echo "LANG=en_US.UTF-8" > /etc/locale.conf
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
echo "export LANG=en_US.UTF-8" >> /etc/profile
echo "export LC_ALL=en_US.UTF-8" >> /etc/profile

# Install essential tools
apk add \
    vscodium \
    btop \
    curl \
    nano \
    fastfetch \
    librewolf \
    bash-completion \
    power-profiles-daemon \
    intel-media-driver \
    bluez bluez-openrc

# Install GNOME (minimal)
setup-desktop gnome --no-install-recommends

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
apk add cargo

# Virtualization setup
echo "Checking virtualization support..."
if [ -z "$(grep -E 'vmx|svm' /proc/cpuinfo)" ]; then
    echo "WARNING: Virtualization extensions not found in /proc/cpuinfo"
    echo "You may need to enable virtualization in your BIOS/UEFI settings"
else
    echo "Virtualization support detected in CPU"
fi

# Install virt-manager components
apk add \
    libvirt libvirt-daemon libvirt-client libvirt-daemon-openrc \
    virt-manager qemu qemu-img qemu-system-x86_64 qemu-modules \
    ebtables dnsmasq bridge-utils iptables openrc libvirt-bash-completion

# Load KVM modules
modprobe kvm
modprobe kvm_intel 2>/dev/null || modprobe kvm_amd 2>/dev/null

# Start and enable libvirt daemon
rc-update add libvirtd
rc-service libvirtd start

# Add user to libvirt group
MAIN_USER=$(ls /home | head -n 1)
if [ -n "$MAIN_USER" ]; then
    adduser $MAIN_USER libvirt
    echo "Added user $MAIN_USER to libvirt group"
fi

# NetworkManager setup - critical for GNOME network visibility
apk add \
    networkmanager \
    networkmanager-cli \
    networkmanager-tui \
    networkmanager-wifi \
    networkmanager-openrc

# Configure NetworkManager
cat > /etc/NetworkManager/NetworkManager.conf <<EOF
[main]
dhcp=internal
plugins=ifupdown,keyfile

[ifupdown]
managed=true

[device]
wifi.scan-rand-mac-address=yes
wifi.backend=wpa_supplicant
EOF

# Stop conflicting services and enable NetworkManager
rc-service networking stop
rc-service wpa_supplicant stop
rc-update del networking boot
rc-update del wpa_supplicant boot

rc-service networkmanager restart
rc-update add networkmanager default

# Polkit setup
rc-service polkit start
rc-update add polkit default

# Remove unnecessary GNOME apps
apk del \
    gnome-weather \
    gnome-contacts \
    cheese \
    gnome-tour \
    gnome-music \
    gnome-calendar \
    yelp \
    simple-scan \
    xsane \
    totem \
    snapshot \
    gnome-software \
    firefox \
    epiphany

# Ensure NetworkManager applet is installed for GNOME
apk add network-manager-applet

# Verify network visibility fix
if ! apk info -e network-manager-applet >/dev/null; then
    echo "Installing network-manager-applet for GNOME network visibility"
    apk add network-manager-applet
fi

echo "Network troubleshooting:"
echo "1. Ensure NetworkManager is running: rc-service networkmanager status"
echo "2. Check if interfaces are managed: nmcli device status"
echo "3. For wired connections, try: nmcli connection add type ethernet ifname eth0"

read -p "Press [Enter] to reboot..."
reboot