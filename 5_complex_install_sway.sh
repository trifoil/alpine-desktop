#!/bin/bash
# Script d'installation et de lancement de sway sur Alpine Linux
# Ce script installe sway et ses dépendances, prépare la configuration utilisateur
# et lance sway dans un environnement non-root.
#
# Usage :
#   ./install_sway.sh [-u USER]
# Si l'option -u (ou --user) n'est pas précisée, le script essaie d'utiliser la variable SUDO_USER,
# sinon il vous demandera de saisir le nom de l'utilisateur (ne pas utiliser "root").

# Activez un mode strict pour stopper le script en cas d'erreur
set -euo pipefail

# Fonction d'arrêt en cas d'erreur
error_exit() {
    echo "[Erreur] $1" >&2
    exit 1
}

# Vérification que le script est exécuté en tant que root
if [ "$(id -u)" -ne 0 ]; then
    error_exit "Ce script doit être exécuté en tant que root."
fi

# Traitement des arguments pour spécifier l'utilisateur cible
TARGET_USER=""
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -u|--user)
            TARGET_USER="$2"
            shift
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-u USER]"
            exit 0
            ;;
        *)
            echo "Argument inconnu: $1"
            exit 1
            ;;
    esac
done

# Détermination de l'utilisateur cible
if [ -z "$TARGET_USER" ]; then
    if [ "${SUDO_USER:-}" != "" ] && [ "$SUDO_USER" != "root" ]; then
        TARGET_USER="$SUDO_USER"
    else
        read -p "Entrez le nom de l'utilisateur pour lancer sway (ne pas utiliser 'root') : " TARGET_USER
        if [ "$TARGET_USER" = "root" ] || [ -z "$TARGET_USER" ]; then
            error_exit "Nom d'utilisateur invalide."
        fi
    fi
fi

# Récupération du répertoire home de l'utilisateur cible
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
    error_exit "Répertoire home non trouvé pour l'utilisateur $TARGET_USER."
fi

echo "Installation de sway et des dépendances pour l'utilisateur $TARGET_USER ($TARGET_HOME)..."

# Vérification de la connectivité Internet
if ! ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    error_exit "Connexion Internet non disponible. Veuillez vérifier votre réseau."
fi

# Mise à jour des dépôts apk
echo "Mise à jour des dépôts apk..."
apk update || error_exit "Échec de la mise à jour des dépôts apk."

# Optionnel : proposer une mise à niveau du système (peut prendre un certain temps)
echo "Souhaitez-vous mettre à niveau le système ? (y/N)"
read -r upgrade_choice
if [[ "$upgrade_choice" =~ ^[Yy]$ ]]; then
    apk upgrade || error_exit "Échec de la mise à niveau du système."
fi

# Installation des paquets nécessaires
echo "Installation des paquets nécessaires (sway, swaybg, swaylock, swayidle, waybar, wofi, grim, slurp)..."
apk add --no-cache sway swaybg swaylock swayidle waybar wofi grim slurp || \
    error_exit "Échec de l'installation des paquets sway et dépendances."

# Installation d'un terminal (ici alacritty)
echo "Installation du terminal alacritty (optionnel)..."
apk add --no-cache alacritty || echo "Attention : l'installation d'alacritty a échoué. Vous pouvez installer un terminal de votre choix."

# Préparation de la configuration de sway pour l'utilisateur cible
SWAY_CONFIG_DIR="$TARGET_HOME/.config/sway"
if [ ! -d "$SWAY_CONFIG_DIR" ]; then
    echo "Création du répertoire de configuration $SWAY_CONFIG_DIR..."
    mkdir -p "$SWAY_CONFIG_DIR" || error_exit "Impossible de créer le répertoire $SWAY_CONFIG_DIR."
    chown "$TARGET_USER":"$TARGET_USER" "$SWAY_CONFIG_DIR"
fi

SWAY_CONFIG_FILE="$SWAY_CONFIG_DIR/config"
if [ ! -f "$SWAY_CONFIG_FILE" ]; then
    if [ -f /etc/sway/config ]; then
        echo "Copie du fichier de configuration par défaut depuis /etc/sway/config..."
        cp /etc/sway/config "$SWAY_CONFIG_FILE" || error_exit "Échec de la copie du fichier de configuration."
    else
        echo "Création d'une configuration minimale pour sway..."
        cat << 'EOF' > "$SWAY_CONFIG_FILE"
# Configuration minimale pour sway
set $mod Mod4

# Lancement du terminal
bindsym $mod+Return exec alacritty

# Lanceur d'applications
bindsym $mod+d exec wofi --show drun

# Quitter une fenêtre
bindsym $mod+Shift+q kill

# Recharger la configuration
bindsym $mod+Shift+c reload

# Quitter sway
bindsym $mod+Shift+e exec swaymsg exit

# Définition d'un fond d'écran (ici une couleur unie)
output * bg #282c34 solid_color
EOF
    fi
    chown "$TARGET_USER":"$TARGET_USER" "$SWAY_CONFIG_FILE"
fi

echo "Configuration de sway terminée."

# Lancement de sway en tant que l'utilisateur cible
echo "Lancement de sway pour l'utilisateur $TARGET_USER..."
# La commande suivante passe à l'environnement de l'utilisateur non-root et lance sway.
su - "$TARGET_USER" -c "sway" || error_exit "Échec du lancement de sway."

echo "Script terminé avec succès."
