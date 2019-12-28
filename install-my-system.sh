#!/bin/sh

DRIVE=/dev/sda
DRIVE_EFI = "$DRIVE"1
DRIVE_CRYPT = "$DRIVE"2

CRYPT_NAME = "main"

clear
echo "Installiere ARCH Linux"

gdisk $DRIVE

mkfs.vfat -F 32 -n EFI $DRIVE_EFI
cryptsetup luksFormat -c aes-xts-plain64 -s 512 -y $DRIVE_CRYPT

cryptsetup luksOpen $DRIVE_CRYPT $CRYPT_NAME


