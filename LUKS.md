```
setup-alpine
```

Keyboard: be.
Keyboard variation: us.
Hostname: adolf.hitler.
Network adapter: wlan0.
Wifi network.
Wifi password.
IP address: dhcp.
Networks: done.
Manual network configuration: n.
root password: yyy
Time zone: Europe/Brussels.
User account: x.


stop when asked about disks (ctrl+c)

install dependancies

```sh
apk add lsblk 
apk add gptfdisk 
apk add btrfs-progs 
apk add e2fsprogs
apk add cryptsetup
apk add lvm2
apk add udev
rc-service udev start
rc-update add udev
```


btrfs module kernel activation

```sh
modprobe btrfs
```

find which disk is yours
```sh
lsblk
```

example with vda
```sh
gdisk /dev/vda
```


```sh
n
```

Fill in :
```
Partition number (1-128, default 1): 1
First Sector (34-41943006, default = 2048) or {+-}size{KMGTP}: 2048
Last Sector (2048-41943006, default = 41940991) or {+-}size{KMGTP}: +512M
Hex code GUID (L to show codes, Enter = 8300): ef00
```

```sh
n
```

Fill in :
```
Partition number (1-128, default 1): 2
First Sector (34-41943006, default = 2048) or {+-}size{KMGTP}: (Press Enter for default)
Last Sector (y-41943006n, default = 41940991) or {+-}size{KMGTP}: (Press Enter for default)
Hex code GUID (L to show codes, Enter = 8300): 8309
```
write table to disk
```sh
w
```

notify the os of partitions changes
```sh
partprobe /dev/vda
```


```sh
lsblk
```

answer is like
```
NAME   MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
vda    253:0    0    20G  0 disk
├─vda1 253:1    0   512M  0 part
└─vda2 253:2    0  19.5G  0 part
```


add the nodes and (replace the major number from lsblk) (to do if udev did not create them and forbids the cryptsetup)
```sh
mknod /dev/vda1 b 253 1
mknod /dev/vda2 b 253 2
```


## LUKS config 

password for the whole disk (see https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Encryption_options_for_LUKS_mode for details)

```sh
cryptsetup luksFormat /dev/vda2
```

type 
```
YES
```

decrypt the partition
```sh
cryptsetup luksOpen /dev/vda2 lvmcrypt
```
## LWM config

```sh
pvcreate /dev/mapper/lvmcrypt
```

```sh
vgcreate vg0 /dev/mapper/lvmcrypt
```

```sh
lvcreate -L 16G vg0 -n swap # Same amount as the device RAM
lvcreate -L 40G vg0 -n alpine # root
lvcreate l 100%FREE vg0 -n home # home, uses remaining space
```



to check
```sh
pvs     # List physical volumes
vgs     # List volume groups
lvs     # List logical volumes
lsblk   # Check hierarchy
```


```sh
nano /etc/apk/repositories
```

uncomment the community repo

```sh
apk add exfatprogs
```

create filesystem
```sh
mkfs.exfat /dev/vda1
mkfs.btrfs /dev/vg0/alpine
mkfs.ext4 /dev/vg0/home
```

activate swap
```sh
mkswap /dev/vg0/swap
swapon /dev/vg0/swap
```

Create Btrfs Subvolumes

Temporarily mount the alpine partition to create subvolumes.
```sh
mount /dev/vg0/alpine /mnt
```

Create the subvolumes adapted from Snapper’s Suggested filesystem layout (https://wiki.archlinux.org/title/Snapper#Suggested_filesystem_layout)
```sh
btrfs subvolume create /mnt/@ # /
btrfs subvolume create /mnt/@var_log # /var/log
```

Find the id of the @ subvolume. Note it as <root-subvol-id>. It will probably be 256 or something.
```sh
btrfs subvolume list /mnt
```

answer looks like :
```
ID 256 gen 10 top level 5 path @
ID 257 gen 10 top level 5 path @var_log
```

Change the default subvolume to @.
```sh
/bin/ash -i
btrfs subvolume set-default 256 /mnt
exit
```

check that de default subvolume is the correct one
```sh
umount /mnt
mount /dev/vg0/alpine /mnt


btrfs subvolume get-default /mnt
umount /mnt
```

Mount partitions

Create mountpoints and mount our partitions and subvolumes

```sh
mount /dev/vg0/alpine -o subvol=@ /mnt/

# Create mountpoints
mkdir -p /mnt/boot /mnt/home /mnt/var/log

# Mount the remaining subvolumes
mount /dev/vg0/alpine -o subvol=@var_log /mnt/var/log

# Mount the efi system partition
modprobe vfat
modprobe fat
mount /dev/nvme0n1p1 /mnt/boot

# Mount the home partition
mount /dev/vg0/home /mnt/home
```


Install a base alpine system

```sh
BOOTLOADER=none setup-disk -k edge /mnt
```

The BOOTLOADER=none tells the script to not install any bootloader (grub is the default), and -k edge tells the script to install the edge kernel instead of the lts one.



```sh
chroot /mnt
mount -t proc proc /proc
mount -t devtmpfs dev /dev
```



```sh
setup-apkcache
apk add secureboot-hook 
apk add gummiboot-efistub
apk add blkid
```


Edit /etc/kernel-hooks.d/secureboot.conf with the following contents.

```conf
cmdline=/etc/kernel/cmdline
signing_disabled=yes
output_dir="/boot/EFI/Linux"
output_name="alpine-linux-{flavor}.efi"
```

/<efi>/EFI/Linux is a more or less standard directory, and will be discovered by systemd-boot if you have that installed.

Signing is disabled only temporarily until I install the proper keys.

credits to https://www.vixalien.com/blog/an-alpine-setup/#main for LUKS and disk management



important pour booter 

echo "vfat" >> /etc/modules
echo "fat" >> /etc/modules