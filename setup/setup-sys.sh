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

echo "GRUB_CMDLINE_LINUX=\"luks.name=$UUID=main rd.luks.key=/root/root_device.key bootflags=subvol=@\"" >> /etc/default/grub

grub-install --efi-directory=/boot/EFI target=x86_64-efi --bootloader-id=grub --recheck --debug
grub-mkconfig -o /boot/grub/grub.cfg

# initramfs

sed -i s/FILES=.*/\#FILES/ /etc/mkinitcpio.conf
sed -i s/HOOKS=.*/\#HOOKS/ /etc/mkinitcpio.conf

echo "FILES=(/root/root_device.key)" >> /etc/mkinitcpio.conf
echo "HOOKS=(base systemd autodetect keyboard sd-vconsole sd-lvm2 sd-encrypt modconf block filesystem btrfs fsck)" >> /etc/mkinitcpio.conf

mkinitcpio -P

chmod 600 /boot/initramfs-*

# new user

useradd -m -g users -G wheel,video,audio -s /bin/zsh chris
passwd chris

# sudo

pacman -S --noconfirm sudo


# trizen

mkdir ~/AUR && cd ~/AUR
git clone https://aur.archlinux.org/trizen
cd trizen
su chris -c "makepkg -si --noconfirm"
rm -rf ~/AUR

# xorg
su chris -c "trizen -S --noconfirm xorg-server xorg-xinit virtualbox-guest-utils"
localectl set-x11-keymap de pc105 nodeadkeys

# fonts
su chris -c "trizen -S --noconfirm noto-fonts noto-fonts-emoji"

# pulseaudio
su chris -c "trizen -S --noconfirm pulseaudio pavucontrol"

# i3
su chris -c "trizen -S --noconfirm i3-gaps i3blocks i3lock dmenu dunst picom"

# zsh
su chris -c "trizen -S --noconfirm zsh zsh-completions zsh-syntax-highlighting"

# suckless
su chris -c "trizen -S --noconfirm st"

# security

su chris -c "trizen -S pam-gnupg"

# file manager

su chris -c "trizen -S --noconfirm ranger"

# browser

su chris -c "trizen -S --noconfirm firefox"

# image viewer

su chris -c "trizen -S --noconfirm sxiv scrot"

# music

su chris -c "trizen -S --noconfirm mpd mpc ncmpcpp"

# video

su chris -c "trizen -S --noconfirm youtube-dl youtube-viewer mpv"

# mail

su chris -c "trizen -S --noconfirm neomutt mutt-wizard-git"

# utils

su chris -c "trizen -S --noconfirm htop wget curl stow"

su chris -c "cd ~ && git clone https://github.com/chris1006/my-dot-files && cd my-dot-files && stow * -t ~"
