#!/bin/bash
# Script d'installation et de lancement de sway sur Alpine Linux
# Ce script installe sway et ses dépendances, prépare la configuration utilisateur,
# configure les variables d’environnement nécessaires et lance sway dans un environnement non-root.
#
# Usage :
#   ./install_sway.sh [-u USER]
# Si l'option -u (ou --user) n'est pas précisée, le script tente d'utiliser la variable SUDO_USER.
# S'il n'existe aucun utilisateur non-root, une option de création d'utilisateur sera proposée.

# Activer un mode strict pour stopper le script en cas d'erreur
set -euo pipefail

# Fonction d'affichage d'erreur et de sortie
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

# Si TARGET_USER n'a pas été défini par argument, tenter d'utiliser SUDO_USER ou rechercher un utilisateur non-root
if [ -z "$TARGET_USER" ]; then
    if [ "${SUDO_USER:-}" != "" ] && [ "$SUDO_USER" != "root" ]; then
         TARGET_USER="$SUDO_USER"
    else
        # Recherche d'un utilisateur non-root existant dans /etc/passwd
        EXISTING_USER=$(awk -F: '$1!="root" {print $1; exit}' /etc/passwd || true)
        if [ -z "$EXISTING_USER" ]; then
            # Aucun utilisateur non-root trouvé, proposer de créer un nouvel utilisateur
            while true; do
                read -p "Aucun utilisateur non-root n'existe. Voulez-vous en créer un ? (O/n) : " create_choice
                case "$create_choice" in
                    [Oo]* )
                        while true; do
                            read -p "Entrez le nom du nouvel utilisateur : " new_user
                            if [ "$new_user" = "root" ] || [ -z "$new_user" ]; then
                                echo "Nom d'utilisateur invalide. Veuillez réessayer."
                            else
                                if getent passwd "$new_user" > /dev/null; then
                                    echo "L'utilisateur '$new_user' existe déjà. Veuillez réessayer."
                                else
                                    echo "Création de l'utilisateur $new_user..."
                                    adduser -D "$new_user" || error_exit "Échec de la création de l'utilisateur."
                                    TARGET_USER="$new_user"
                                    break 2
                                fi
                            fi
                        done
                        ;;
                    [Nn]* )
                        error_exit "Aucun utilisateur non-root disponible, le script ne peut continuer."
                        ;;
                    * )
                        echo "Veuillez répondre par O ou N."
                        ;;
                esac
            done
        else
            TARGET_USER="$EXISTING_USER"
            echo "Utilisateur existant trouvé: $TARGET_USER"
        fi
    fi
fi

# Récupération et vérification du répertoire home de l'utilisateur cible
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
    error_exit "Répertoire home non trouvé pour l'utilisateur $TARGET_USER. Assurez-vous que l'utilisateur existe."
fi

echo "Installation de sway et des dépendances pour l'utilisateur $TARGET_USER ($TARGET_HOME)..."

# Vérification de la connectivité Internet
if ! ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    error_exit "Connexion Internet non disponible. Veuillez vérifier votre réseau."
fi

# Mise à jour des dépôts apk
echo "Mise à jour des dépôts apk..."
apk update || error_exit "Échec de la mise à jour des dépôts apk."

# Proposition de mise à niveau du système (optionnelle)
echo "Souhaitez-vous mettre à niveau le système ? (y/N)"
read -r upgrade_choice
if [[ "$upgrade_choice" =~ ^[Yy]$ ]]; then
    apk upgrade || error_exit "Échec de la mise à niveau du système."
fi

# Installation des paquets nécessaires pour sway et ses dépendances
echo "Installation des paquets nécessaires (sway, swaybg, swaylock, swayidle, waybar, wofi, grim, slurp)..."
apk add --no-cache sway swaybg swaylock swayidle waybar wofi grim slurp || \
    error_exit "Échec de l'installation des paquets sway et dépendances."

# Installation d'un terminal (alacritty dans cet exemple)
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

# Définition des variables d'environnement pour sway.
# Ces variables indiquent notamment que la session est en Wayland.
TARGET_UID=$(id -u "$TARGET_USER")
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export XDG_RUNTIME_DIR="/run/user/${TARGET_UID}"

echo "Variables d'environnement définies :"
echo "  XDG_SESSION_TYPE=${XDG_SESSION_TYPE}"
echo "  XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP}"
echo "  XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}"

# Lancement de sway en tant qu'utilisateur cible en transmettant les variables d'environnement.
echo "Lancement de sway pour l'utilisateur $TARGET_USER..."
su - "$TARGET_USER" -c "env XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=sway XDG_RUNTIME_DIR=/run/user/${TARGET_UID} sway" || error_exit "Échec du lancement de sway."

echo "Script terminé avec succès."
