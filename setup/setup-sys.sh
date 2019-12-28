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
pacman -Syyu --noconfirm

# services
pacman -S --noconfirm networkmanager acpid dbus avahi cronie

systemctl enable acpid
systemctl enable avahi-daemon
systemctl enable cronie
systemctl enable systemd-timesyncd
systemctl enable NetworkManager

# key for harddrive

dd if=/dev/urandom bs=1M count=4 of=/root/root_device.key
chmod 600 /root/root_device.key

cryptsetup luksAddKey /dev/sda2 /root/root_device.key

echo "main /dev/disk/by-uuid/$UUID /root/root_device.key luks" >> /etc/crypttab

# grub
pacman -S --noconfirm grub efibootmgr

echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
UUID="$(cryptsetup luksUUID /dev/sda2)"
sed -i "s/GRUB_CMDLINE_LINUX=.*/#GRUB_CMDLINE_LINUX/"

echo "GRUB_CMDLINE_LINUX=luks.name=$UUID=main rd.luks.key=/root/root_device.key bootflags=subvol=@" >> /etc/default/grub

grub-install --efi-directory=/boot/EFI target=x86_64-efi --bootloader-id=grub --recheck --debug
grub-mkconfig -o /boot/grub/grub.cfg

# initramfs

sed -i s/FILES=.*/\#FILES/ /etc/mkinitcpio.conf
sed -i s/HOOKS=.*/\#HOOKS/ /etc/mkinitcpio.conf

echo "FILES=(/root/root_device.key)" >> /etc/mkinitcpio.conf
echo "HOOKS=(base systemd autodetect keyboard sd-vconsole sd-lvm2 sd-encrypt modconf block filesystem btrfs fsck)" >> /etc/mkinitcpio.conf

mkinitcpio -P

chmod 600 /boot/initramfs-*
