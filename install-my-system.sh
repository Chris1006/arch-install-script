#!/bin/sh

DRIVE=/dev/sda
DRIVE_EFI="$DRIVE"1
DRIVE_CRYPT="$DRIVE"2

CRYPT_NAME="main"
LVM_NAME="main"
SWAP_NAME="swap"
ROOT_NAME="root"

MAPPER_NAME="/dev/mapper/"$CRYPT_NAME

ROOT_DRIVE=$MAPPER_NAME"-"$ROOT_NAME
SWAP_DRIVE=$MAPPER_NAME"-"$SWAP_NAME


clear
echo "Installiere ARCH Linux"

# setting up partitions
gdisk $DRIVE

# efi setup
mkfs.vfat -F 32 -n EFI $DRIVE_EFI

# crypt setup
cryptsetup luksFormat -c aes-xts-plain64 -s 512 -y $DRIVE_CRYPT
cryptsetup luksOpen $DRIVE_CRYPT $CRYPT_NAME

# lvm setup
pvcreate $MAPPER_NAME
vgcreate $LVM_NAME $MAPPER_NAME

lvcreate -L 2GB -n $SWAP_NAME $LVM_NAME
lvcreate -l 100%FREE -n $ROOT_NAME $LVM_NAME

# setup lvm drives (swap and root)
mkswap -L p_swap $SWAP_DRIVE
mkfs.btrfs -L p_root $ROOT_DRIVE

swapon $SWAP_DRIVE

mount $ROOT_DRIVE /mnt

cd /mnt

# create btrfs subvols
btrfs subvol create @
btrfs subvol create @home
btrfs subvol create @log
btrfs subvol create @pkg
btrfs subvol create @snapshots

cd /

umount -R /mnt

mount -o subvol=@ $ROOT_DRIVE /mnt

mkdir -p /mnt/{boot/EFI,home,var/log,var/cache/pacman/pkg,.snapshots,.btrfs}

mount $ROOT_DRIVE -o subvol=@home /mnt/home
mount $ROOT_DRIVE -o subvol=@snapshots /mnt/.snapshots
mount $ROOT_DRIVE -o subvol=@log /mnt/var/log
mount $ROOT_DRIVE -o subvol=@pkg /mnt/var/cache/pacman/pkg
mount $ROOT_DRIVE /mnt/.btrfs

pacstrap base base-devel btrfs vim zsh git linux-zen linux-zen-headers linux-firmware /mnt

arch-chroot /mnt
