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
apk add vscodium 
apk add btop 
apk add curl 
apk add nano 
apk add fastfetch 
apk add librewolf 
apk add bash-completion 
apk add power-profiles-daemon
rc-init apk-polkit-server
apk add intel-media-driver
apk add bluez bluez-openrc


read -p "Press [Enter] to continue..."

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
apk add cargo


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

apk add networkmanager-cli 
apk add networkmanager-tui
apk add networkmanager-wifi

cat <<EOF
Contents of /etc/NetworkManager/NetworkManager.conf
[main] 
dhcp=internal
plugins=ifupdown,keyfile

[ifupdown]
managed=true

[device]
wifi.scan-rand-mac-address=yes
wifi.backend=wpa_supplicant
EOF

rc-service networking stop
rc-service wpa_supplicant stop

rc-service networkmanager restart

#for user in $(cat /etc/passwd | cut -d: -f1); do
#  adduser $user plugdev
#done

rc-service polkit start
rc-update add polkit default
rc-update add networkmanager default
rc-update del networking boot
rc-update del wpa_supplicant boot


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

# Remove unnecessary GNOME apps
apk del gnome-weather
#apk del gnome-clocks
apk del gnome-contacts
apk del cheese
apk del gnome-tour
apk del gnome-music
apk del gnome-calendar
apk del yelp
apk del simple-scan
apk del xsane
apk del totem
apk del snapshot
apk del gnome-software
apk del firefox
apk del epiphany

read -p "Press [Enter] to continue..."

# Reboot
reboot