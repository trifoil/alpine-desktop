#!/bin/bash

# # Install LaTeX (Full) - with proper dependencies
# apk add build-base perl wget tar gnupg ghostscript libpng-dev harfbuzz-dev

# # Install TeX Live
# wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
# wget https://mirror.ctan.net/systems/texlive/tlnet/install-tl-unx.tar.gz
# wget https://mirror.ctan.org/ctan/systems/texlive/tlnet/install-tl-unx.tar.gz
# wget https://ctan.mines-albi.fr/systems/texlive/tlnet/install-tl-unx.tar.gz
# wget https://za.mirrors.cicku.me/ctan/systems/texlive/tlnet/install-tl-unx.tar.gz

 
# tar -xzf install-tl-unx.tar.gz
# cd install-tl-*

# # Install TeX Live with basic scheme
# TEXLIVE_INSTALL_PREFIX=/usr/local ./install-tl \
#     --scheme=basic \
#     --no-interaction

# cd ..
# rm -rf install-tl-* install-tl-unx.tar.gz

# # Add TeX Live to PATH
# echo 'export PATH="/usr/local/2025/bin/x86_64-linuxmusl:$PATH"' >> /etc/profile

# apk add texstudio


apk update && apk add texmf-dist texlive-full

apk update && apk add texstudio

read -n 1 -s -r -p "Done. Press any key to continue..."

