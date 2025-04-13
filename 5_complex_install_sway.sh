#!/bin/sh

# Fonction pour vérifier le succès d'une commande
check_command() {
  if [ $? -ne 0 ]; then
    echo "Erreur lors de l'exécution de la commande: $1" >&2
    exit 1
  fi
}

# Mise à jour des dépôts et installation des dépendances
echo "Mise à jour des dépôts et installation des dépendances..."
apk update
check_command "apk update"

apk upgrade
check_command "apk upgrade"

apk add --no-cache \
  sway \
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
  noto-fonts \
  noto-fonts-cjk \
  noto-fonts-emoji \
  python3 \
  py3-pip \
  i3bar \
  mesa-dri
check_command "apk add dependencies"

# Installer swaybar et swaybg
apk add --no-cache swaybar swaybg
check_command "apk add swaybar swaybg"

# Activer et démarrer dbus
echo "Activation et démarrage de dbus..."
rc-update add dbus
check_command "rc-update add dbus"

service dbus start
check_command "service dbus start"

# Activer NetworkManager
echo "Activation et démarrage de NetworkManager..."
rc-update add networkmanager
check_command "rc-update add networkmanager"

service networkmanager start
check_command "service networkmanager start"

# Configurer les variables d'environnement pour Sway
echo "Configuration des variables d'environnement..."
{
  echo "export XDG_SESSION_TYPE=wayland"
  echo "export XDG_SESSION_DESKTOP=sway"
  echo "export XDG_CURRENT_DESKTOP=sway"
  echo "export GDK_BACKEND=wayland"
  echo "export QT_QPA_PLATFORM=wayland"
  echo "export MOZ_ENABLE_WAYLAND=1"
} >> /etc/profile

check_command "Modification de /etc/profile"

# Recharger les variables d'environnement
source /etc/profile

# Créer le fichier de configuration de Sway
echo "Création de la configuration par défaut de Sway..."
mkdir -p ~/.config/sway
check_command "mkdir ~/.config/sway"

curl -o ~/.config/sway/config https://raw.githubusercontent.com/swaywm/sway/master/config
check_command "curl -o ~/.config/sway/config"

# Configurer Alacritty
echo "Configuration de Alacritty..."
mkdir -p ~/.config/alacritty
check_command "mkdir ~/.config/alacritty"

curl -o ~/.config/alacritty/alacritty.yml https://raw.githubusercontent.com/alacritty/alacritty/master/alacritty.yml
check_command "curl -o ~/.config/alacritty/alacritty.yml"

# Vérifier que les fichiers de configuration existent avant de démarrer Sway
if [ ! -f ~/.config/sway/config ]; then
  echo "Le fichier de configuration Sway est manquant. Veuillez vérifier la configuration."
  exit 1
fi

if [ ! -f ~/.config/alacritty/alacritty.yml ]; then
  echo "Le fichier de configuration Alacritty est manquant. Veuillez vérifier la configuration."
  exit 1
fi

# Démarrer Sway
echo "Démarrage de Sway..."
startx
check_command "startx"

# Afficher le message de fin
echo "Installation et configuration de Sway terminées avec succès !"
