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
mkswap --force -L p_swap $SWAP_DRIVE
mkfs.btrfs --force -L p_root $ROOT_DRIVE

swapon $SWAP_DRIVE

umount -R /mnt

mount $ROOT_DRIVE /mnt

# create btrfs subvols
btrfs subvol create /mnt/@
btrfs subvol create /mnt/@home
btrfs subvol create /mnt/@log
btrfs subvol create /mnt/@pkg
btrfs subvol create /mnt/@snapshots

umount -R /mnt

mount $ROOT_DRIVE -o subvol=@ /mnt

cp ./setup/setup-sys.sh /mnt/

mkdir -p /mnt/{boot/EFI,home,var/log,var/cache/pacman/pkg,.snapshots,.btrfs}

mount $ROOT_DRIVE -o subvol=@home /mnt/home
mount $ROOT_DRIVE -o subvol=@snapshots /mnt/.snapshots
mount $ROOT_DRIVE -o subvol=@log /mnt/var/log
mount $ROOT_DRIVE -o subvol=@pkg /mnt/var/cache/pacman/pkg
mount $ROOT_DRIVE /mnt/.btrfs

mount $DRIVE_EFI /mnt/boot/EFI

pacstrap /mnt base base-devel btrfs-progs vim zsh git linux-zen linux-zen-headers linux-firmware

gen-fstab -U /mnt >> /mnt/etc/fstab

# setting up target system
arch-chroot /mnt sh /setup-sys.sh

# chrooting to target system
# arch-chroot /mnt

# rebooting system
umount -R /mnt
swapoff $SWAP_DRIVE

#reboot
