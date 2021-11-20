#part2
printf '\033c'
pacman -Syu --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
ln -sf /usr/share/zoneinfo/Africa/Algeirs /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=fr" > /etc/vconsole.conf
echo BlissIO > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       BlissIO.localdomain BlissIO" >> /etc/hosts
mkinitcpio -P
passwd
pacman --noconfirm -S grub networkmanager
lsblk
echo "Enter boot partition: " 
read bootpartition
mkdir /boot
mount $bootpartition /boot 
grub-install $bootpartition
sed -i 's/quiet/pci=noaer/g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=2/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S --noconfirm xorg-server  nano sudo \
     noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome \
     sxiv mpv zathura zathura-pdf-mupdf \
     fzf man-db feh python-pywal youtube-dl xclip \
     zip unzip unrar p7zip xdotool papirus-icon-theme brightnessctl  \
     pipewire pipewire-pulse \
     vim arc-gtk-theme firefox \
     xcompmgr libnotify dunst slock jq \
     dhcpcd networkmanager pamixer

systemctl enable NetworkManager 
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
useradd -m -G wheel real
passwd real
echo "Pre-Installation Finish Reboot now"
exit 
