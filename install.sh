#!/bin/bash

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Try 'sudo sh install.sh'"
    exit 1
fi

# Add Alpine's edge/testing repo
echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Update & upgrade
apk update && apk upgrade

# Fix UTF-8 locale for btop (Alpine-specific method)
apk add musl-locales
echo "LANG=en_US.UTF-8" > /etc/locale.conf
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Install GNOME
setup-desktop gnome

# Install essential tools (now including btop)
apk add vscodium btop curl nano fastfetch librewolf gnome-abrt bash-completion

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
apk add cargo

# Remove unnecessary GNOME apps
apk del gnome-weather gnome-clocks gnome-contacts cheese gnome-tour gnome-music \
      gnome-calendar yelp simple-scan xsane totem snapshot gnome-software firefox WebKitWebProcess

# Install LaTeX (Full) - with proper dependencies
apk add build-base perl wget tar gnupg ghostscript libpng-dev harfbuzz-dev

# Install TeX Live
wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
tar -xzf install-tl-unx.tar.gz
cd install-tl-*

# Install TeX Live with basic scheme
TEXLIVE_INSTALL_PREFIX=/usr/local ./install-tl \
    --scheme=basic \
    --no-interaction

cd ..
rm -rf install-tl-* install-tl-unx.tar.gz

# Add TeX Live to PATH
echo 'export PATH="/usr/local/2025/bin/x86_64-linuxmusl:$PATH"' >> /etc/profile

apk add texstudio

# Install GitHub Desktop via Flatpak
apk add flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub io.github.shiftey.Desktop -y

# Make UTF-8 locale persistent
echo "export LANG=en_US.UTF-8" >> /etc/profile
echo "export LC_ALL=en_US.UTF-8" >> /etc/profile

# Virtualization setup
echo "Checking virtualization support..."
if [ -z "$(grep -E 'vmx|svm' /proc/cpuinfo)" ]; then
    echo "WARNING: Virtualization extensions not found in /proc/cpuinfo"
    echo "You may need to enable virtualization in your BIOS/UEFI settings"
else
    echo "Virtualization support detected in CPU"
fi

# Install virt-manager and all required components
echo "Installing virtualization packages..."
apk add libvirt libvirt-daemon libvirt-client libvirt-daemon-openrc virt-manager qemu qemu-img qemu-system-x86_64 qemu-modules ebtables dnsmasq bridge-utils iptables openrc libvirt-bash-completion

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
else
    echo "No regular user found in /home directory"
fi

# Verify installation
if virsh list --all &>/dev/null; then
    echo "libvirt is working correctly"
else
    echo "libvirt installation may have issues - check logs with: rc-service libvirtd status"
    echo "You might need to load kernel modules manually:"
    echo "modprobe kvm"
    echo "modprobe kvm_intel (or kvm_amd depending on your CPU)"
    echo "Then restart libvirt: rc-service libvirtd restart"
fi

# Reboot
reboot