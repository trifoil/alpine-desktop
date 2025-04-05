#!/bin/ash
# Alpine Linux Auto-Installer with LUKS/LVM (Disk Setup First)
# Usage: wget https://raw.githubusercontent.com/yourusername/alpine-autoinstall/main/install.sh -O install.sh && chmod +x install.sh && ./install.sh

# Configuration
DISK="/dev/vda"                         # Target disk (change this!)
HOSTNAME="alpinebox"                    # System hostname
KEYMAP="us"                             # Keyboard layout
TIMEZONE="Europe/Brussels"              # Timezone
USERNAME="user"                         # Main user
LUKS_PASSWORD="changeme123"             # LUKS encryption password
ROOT_PASSWORD="rootpass123"             # root password
USER_PASSWORD="userpass123"             # Main user password
EFI_SIZE="512M"                         # EFI partition size
SWAP_SIZE="2G"                          # Swap size (adjust to your RAM)
ROOT_SIZE="5G"                          # Root partition size
REPO_URL="http://dl-cdn.alpinelinux.org/alpine/edge/main"  # Alpine repository

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root!${NC}"
    exit 1
fi

# Install required packages first
echo -e "${GREEN}Installing required tools...${NC}"
apk add --no-cache parted 
apk add --no-cache gptfdisk 
apk add --no-cache cryptsetup 
apk add --no-cache lvm2 
apk add --no-cache btrfs-progs
apk add --no-cache e2fsprogs
apk add --no-cache lsblk


# Verify target disk
echo -e "${YELLOW}Target disk: $DISK${NC}"
if [ ! -b "$DISK" ]; then
    echo -e "${RED}Invalid disk specified!${NC}"
    exit 1
fi

# Show disk information
echo -e "${GREEN}Disk information:${NC}"
fdisk -l $DISK || {
    echo -e "${RED}Error checking disk!${NC}"
    exit 1
}

# Partition the disk
echo -e "${GREEN}Partitioning $DISK...${NC}"
wipefs -a $DISK
parted -s $DISK mklabel gpt
parted -s $DISK mkpart primary fat32 1MiB $EFI_SIZE
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary ${EFI_SIZE} 100%

# Setup encryption
echo -e "${GREEN}Setting up LUKS encryption...${NC}"
echo -n "$LUKS_PASSWORD" | cryptsetup luksFormat --type luks2 ${DISK}2 -
echo -n "$LUKS_PASSWORD" | cryptsetup open ${DISK}2 cryptroot

# Setup LVM
echo -e "${GREEN}Setting up LVM...${NC}"
pvcreate /dev/mapper/cryptroot
vgcreate vg0 /dev/mapper/cryptroot
lvcreate -L $SWAP_SIZE vg0 -n swap
lvcreate -L $ROOT_SIZE vg0 -n root
lvcreate -l 100%FREE vg0 -n home

# Create filesystems
echo -e "${GREEN}Creating filesystems...${NC}"
mkfs.vfat -F32 ${DISK}1
mkfs.btrfs -L root /dev/vg0/root
mkfs.ext4 -L home /dev/vg0/home
mkswap /dev/vg0/swap

# Mount everything
echo -e "${GREEN}Mounting filesystems...${NC}"
mount /dev/vg0/root /mnt
mkdir -p /mnt/boot /mnt/home
mount ${DISK}1 /mnt/boot
mount /dev/vg0/home /mnt/home
swapon /dev/vg0/swap

# Install Alpine base system
echo -e "${GREEN}Installing Alpine base system...${NC}"
cat <<EOF | setup-disk -o /tmp/answerfile -k edge -s 0 /mnt
$HOSTNAME
$KEYMAP
$TIMEZONE
$REPO_URL
EOF

# Chroot configuration
echo -e "${GREEN}Configuring installed system...${NC}"
mount -o bind /dev /mnt/dev
mount -t proc none /mnt/proc
mount -t sysfs none /mnt/sys

# Create chroot script
cat > /mnt/configure.sh <<"EOF"
#!/bin/ash
# Configuration inside chroot

# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Create user
adduser -D -g "$USERNAME" $USERNAME
echo "$USERNAME:$USER_PASSWORD" | chpasswd
addgroup $USERNAME wheel

# Configure repositories
cat > /etc/apk/repositories <<REPO
$REPO_URL
http://dl-cdn.alpinelinux.org/alpine/edge/community
REPO

# Install essential packages
apk update
apk add grub grub-efi efibootmgr cryptsetup lvm2

# Configure crypttab
echo "cryptroot UUID=$(blkid -s UUID -o value ${DISK}2) none luks" >> /etc/crypttab

# Configure mkinitfs for encryption
cat > /etc/mkinitfs/mkinitfs.conf <<INITFS
features="base ide scsi usb ext4 lvm cryptsetup cryptkey"
INITFS
mkinitfs -c /etc/mkinitfs/mkinitfs.conf $(ls /lib/modules)

# Install GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=alpine
cat > /etc/default/grub <<GRUB
GRUB_CMDLINE_LINUX="cryptroot=UUID=$(blkid -s UUID -o value ${DISK}2) cryptdm=cryptroot root=/dev/vg0/root"
GRUB_DEFAULT=0
GRUB_TIMEOUT=2
GRUB_DISABLE_RECOVERY=true
GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
rc-update add devfs sysinit
rc-update add dmesg sysinit
rc-update add mdev sysinit
rc-update add cryptroot boot
rc-update add lvm boot
rc-update add hwdrivers boot
rc-update add modules boot
rc-update add swapon boot
EOF

# Make chroot script executable and run it
chmod +x /mnt/configure.sh
chroot /mnt /bin/ash -c "DISK=$DISK USERNAME=$USERNAME USER_PASSWORD=$USER_PASSWORD ROOT_PASSWORD=$ROOT_PASSWORD REPO_URL=$REPO_URL /configure.sh"

# Cleanup
echo -e "${GREEN}Cleaning up...${NC}"
umount -R /mnt
swapoff -a

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}Don't forget to:${NC}"
echo "1. Remove the installation media"
echo "2. Set BIOS to boot from the correct disk"
echo -e "3. Use the password ${RED}'$LUKS_PASSWORD'${NC} when prompted for disk encryption"