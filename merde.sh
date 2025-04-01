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
setup-desktop gnome

# Install essential tools (now including btop)
apk add vscodium btop curl nano fastfetch librewolf gnome-abrt bash-completion 


# Install LaTeX (Full) - with proper dependencies
apk add build-base perl wget tar gnupg ghostscript libpng-dev harfbuzz-dev
read -n 1 -s -r -p "dep. Press any key to continue..."
# Install TeX Live
wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
wget https://mirror.ctan.net/systems/texlive/tlnet/install-tl-unx.tar.gz
wget https://mirror.ctan.org/ctan/systems/texlive/tlnet/install-tl-unx.tar.gz
wget https://ctan.mines-albi.fr/systems/texlive/tlnet/install-tl-unx.tar.gz
wget https://za.mirrors.cicku.me/ctan/systems/texlive/tlnet/install-tl-unx.tar.gz

read -n 1 -s -r -p "mirr. Press any key to continue..."
tar -xzf install-tl-unx.tar.gz
cd install-tl-*

# Install TeX Live with basic scheme
TEXLIVE_INSTALL_PREFIX=/usr/local ./install-tl --scheme=basic --no-interaction
cd ..
rm -rf install-tl-* install-tl-unx.tar.gz
read -n 1 -s -r -p "tex inst done. Press any key to continue..."

# Add TeX Live to PATH
echo 'export PATH="/usr/local/2025/bin/x86_64-linuxmusl:$PATH"' >> /etc/profile
read -n 1 -s -r -p "tex path done. Press any key to continue..."

apk add texstudio


read -n 1 -s -r -p "Done. Press any key to continue..."