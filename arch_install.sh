# == MY ARCH SETUP INSTALLER == #
#part1
printf '\033c'
echo "Welcome to the arch-install script"
pacman --noconfirm -Sy archlinux-keyring
loadkeys fr
timedatectl set-ntp true && sleep 3
echo " !! Remember only one partition adn make it bootlable!! "
lsblk
echo "Enter the drive: "
read drive
cfdisk $drive 
echo "Enter the linux partition: "
read partition
mkfs.ext4 $partition 
mount $partition /mnt 
pacstrap /mnt base base-devel linux linux-firmware vim nvidia nvidia-utils grub networkmanager
genfstab -U /mnt >> /mnt/etc/fstab
sed '1,/^#part2$/d' arch_install.sh > /mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt ./arch_install2.sh
exit 

#part2
printf '\033c'
pacman -S --noconfirm sed
ln -sf /usr/share/zoneinfo/Africa/Casablanca /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=fr" > /etc/vconsole.conf
echo "Hostname: "
read hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts
mkinitcpio -P
passwd
pacman --noconfirm -S grub networkmanager
systemctl enable NetworkManager
lsblk
echo -n "Wich drive did you mount everything to ? [eg : sda]" 
grub-install $bootpartition
sed -i 's/quiet/pci=noaer/g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S --noconfirm xorg-server xorg-xinit noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome \
     sxiv mpv ffmpeg imagemagick fzf man-db yt-dlp xclip ntfs-3g git vim rsync firefox jq picom alacritty python-pywal maim zip unzip unrar p7zip \
     pipewire pipewire-pulse pipewire-alsa libnotify dunst wpa_supplicant cmus lxappearance
sed -i 's/#%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
echo "Enter Username: "
read username
useradd -m -G wheel $username
passwd $username
cd /home/$username
echo "Pre-Installation Finish Reboot now"
ai3_path=/home/$username/arch_install3.sh
sed '1,/^#part3$/d' arch_install2.sh > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/sh $username
exit

#part3
printf '\033c'
cd $HOME &&
echo "Setting up the config folder" &&
mkdir .config  &&
cd .config/ &&
git clone https://aur.archlinux.org/pikaur.git &&
cd pikaur && makepkg -si && pikaur nerd-fonts-jetbrains-mono || echo "pikaur failed to install"
git clone https://github.com/shaolingit/Dotfiles.git &&
mv .config/Dotfiles/config/alacritty . &&
mv Dotfiles/suckless-old/* . &&
sudo make clean install -C dwm/ || echo "dwm failed to compile"
sudo make clean install -C dmenu/  || echo "dmenu failed to compile"
sudo make clean install -C slstatus/ || echo "slstatus failed to compile"
cd $HOME && 
mv .config/Dotfiles/config/bashrc .bashrc &&
mv .config/Dotfiles/config/xinitrc .xinitrc
exit

exit
