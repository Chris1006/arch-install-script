#!/bin/sh

# locale.conf
echo LANG=de_DE.UTF-8 >> /etc/locale.conf
echo LANGUAGE=de_DE >> /etc/locale.conf
echo LC_ALL=C >> /etc/locale.conf

# timezone
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# locale gen
sed -i s/#de_DE.UTF-8/de_DE.UTF-8/
locale-gen

# keymap
echo KEYMAP=de-latin1-nodeadkeys >> /etc/vconsole.conf

# hostname
echo arch-encrypted >> /etc/hostname

# set root password
passwd

# system update
pacman -Syyu --no-confirm

# services
pacman -S --no-confirm networkmanager acpid dbus avahi cronie

systemctl enable acpid
systemctl enable avahi-daemon
systemctl enable cronie
systemctl enable systemd-timesyncd
systemctl enable NetworkManager

# grub
pacman -S --no-confirm grub efibootmgr

grub-install --efi-directory=/boot/EFI target=x86_64-efi --bootloader-id=grub --recheck --debug
