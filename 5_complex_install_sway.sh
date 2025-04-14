#!/bin/bash
# Script d'installation et de lancement de sway sur Alpine Linux.
# Ce script vérifie la version d’Alpine, met à jour (si nécessaire) les dépôts,
# installe sway et ses dépendances, propose de créer un utilisateur non-root
# si aucun n'existe, configure l'environnement et lance sway.
#
# Usage :
#   ./install_sway.sh [-u USER]
# Si l'option -u (ou --user) n'est pas précisée, le script tente d'utiliser la variable SUDO_USER.
# S'il n'existe aucun utilisateur non-root, une option de création d'utilisateur sera proposée.

# Active le mode "strict" afin que le script s'arrête en cas d'erreur.
set -euo pipefail

# Fonction d'affichage d'erreur et sortie.
error_exit() {
    echo "[Erreur] $1" >&2
    exit 1
}

# Vérifier que le script est exécuté en tant que root.
if [ "$(id -u)" -ne 0 ]; then
    error_exit "Ce script doit être exécuté en tant que root."
fi

########################################################################
# Vérification de la version d'Alpine et mise à jour des dépôts si besoin
########################################################################
if [ -f /etc/alpine-release ]; then
    # Récupère la version majeure.minor, par exemple "3.2" pour "3.2.2"
    ALPINE_VERSION=$(cut -d. -f1,2 /etc/alpine-release)
else
    error_exit "Fichier /etc/alpine-release introuvable. Impossible de déterminer la version d'Alpine Linux."
fi

# Si Alpine 3.2 est détecté, proposer de mettre à jour les dépôts vers l'archive
if [ "$ALPINE_VERSION" = "3.2" ]; then
    echo "Votre version d'Alpine ($ALPINE_VERSION) est obsolète et les dépôts officiels ne sont plus disponibles."
    echo "Afin de poursuivre, vous pouvez mettre à jour automatiquement le fichier des dépôts vers les archives."
    while true; do
        read -p "Mettre à jour /etc/apk/repositories pour Alpine 3.2 (archive) ? (O/n) : " repo_choice
        case "$repo_choice" in
            [Oo]*|"")
                # Sauvegarde du fichier actuel
                cp /etc/apk/repositories /etc/apk/repositories.bak || error_exit "Impossible de sauvegarder /etc/apk/repositories."
                echo "Sauvegarde réalisée dans /etc/apk/repositories.bak."
                cat <<EOF > /etc/apk/repositories
http://dl-3.alpinelinux.org/alpine/v3.2/main
http://dl-3.alpinelinux.org/alpine/v3.2/community
EOF
                echo "Dépôts mis à jour vers l'archive Alpine 3.2."
                break
                ;;
            [Nn]* )
                error_exit "Mise à jour des dépôts annulée. Pour continuer, mettez à jour manuellement /etc/apk/repositories ou utilisez une version plus récente d'Alpine."
                ;;
            * )
                echo "Veuillez répondre par O (Oui) ou N (Non)."
                ;;
        esac
    done
fi

########################################################################
# Traitement des options pour spécifier l'utilisateur cible
########################################################################
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

########################################################################
# Choix ou création d'un utilisateur non-root
########################################################################
if [ -z "$TARGET_USER" ]; then
    if [ "${SUDO_USER:-}" != "" ] && [ "$SUDO_USER" != "root" ]; then
         TARGET_USER="$SUDO_USER"
    else
        # Recherche d'un utilisateur non-root existant dans /etc/passwd
        EXISTING_USER=$(awk -F: '$1!="root" {print $1; exit}' /etc/passwd || true)
        if [ -z "$EXISTING_USER" ]; then
            # Aucun utilisateur non-root trouvé, proposer la création d'un nouvel utilisateur
            while true; do
                read -p "Aucun utilisateur non-root n'existe. Voulez-vous créer un nouvel utilisateur ? (O/n) : " create_choice
                case "$create_choice" in
                    [Oo]*|"")
                        while true; do
                            read -p "Entrez le nom du nouvel utilisateur : " new_user
                            if [ "$new_user" = "root" ] || [ -z "$new_user" ]; then
                                echo "Nom d'utilisateur invalide. Veuillez réessayer."
                            else
                                if getent passwd "$new_user" > /dev/null; then
                                    echo "L'utilisateur '$new_user' existe déjà. Veuillez réessayer."
                                else
                                    echo "Création de l'utilisateur '$new_user'..."
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
                        echo "Veuillez répondre par O (Oui) ou N (Non)."
                        ;;
                esac
            done
        else
            TARGET_USER="$EXISTING_USER"
            echo "Utilisateur existant trouvé: $TARGET_USER"
        fi
    fi
fi

########################################################################
# Vérification du répertoire home de l'utilisateur cible
########################################################################
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
    error_exit "Répertoire home non trouvé pour l'utilisateur $TARGET_USER. Assurez-vous que l'utilisateur existe."
fi

echo "Installation de sway et des dépendances pour l'utilisateur $TARGET_USER ($TARGET_HOME)..."

########################################################################
# Vérification de la connectivité Internet
########################################################################
if ! ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    error_exit "Connexion Internet non disponible. Veuillez vérifier votre réseau."
fi

########################################################################
# Mise à jour des dépôts apk et proposition de mise à niveau du système
########################################################################
echo "Mise à jour des dépôts apk..."
apk update || error_exit "Échec de la mise à jour des dépôts apk."

echo "Souhaitez-vous mettre à niveau le système ? (y/N)"
read -r upgrade_choice
if [[ "$upgrade_choice" =~ ^[Yy]$ ]]; then
    apk upgrade || error_exit "Échec de la mise à niveau du système."
fi

########################################################################
# Installation des paquets nécessaires pour sway et ses dépendances
########################################################################
echo "Installation des paquets nécessaires (sway, swaybg, swaylock, swayidle, waybar, wofi, grim, slurp)..."
apk add --no-cache sway swaybg swaylock swayidle waybar wofi grim slurp || \
    error_exit "Échec de l'installation des paquets sway et dépendances."

# Installation d'un terminal (ici alacritty, optionnel)
echo "Installation du terminal alacritty (optionnel)..."
apk add --no-cache alacritty || echo "Attention : l'installation d'alacritty a échoué. Vous pouvez installer un terminal de votre choix."

########################################################################
# Préparation de la configuration de sway pour l'utilisateur cible
########################################################################
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

########################################################################
# Définition des variables d'environnement et lancement de sway
########################################################################
# Récupération de l'UID de l'utilisateur pour définir XDG_RUNTIME_DIR
TARGET_UID=$(id -u "$TARGET_USER")
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export XDG_RUNTIME_DIR="/run/user/${TARGET_UID}"

echo "Variables d'environnement définies :"
echo "  XDG_SESSION_TYPE=${XDG_SESSION_TYPE}"
echo "  XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP}"
echo "  XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}"

echo "Lancement de sway pour l'utilisateur $TARGET_USER..."
# Passage dans l'environnement de l'utilisateur cible et lancement de sway avec les variables
su - "$TARGET_USER" -c "env XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=sway XDG_RUNTIME_DIR=/run/user/${TARGET_UID} sway" || error_exit "Échec du lancement de sway."

echo "Script terminé avec succès."
