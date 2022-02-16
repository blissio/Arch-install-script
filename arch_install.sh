# == MY ARCH SETUP INSTALLER == #
#part1
printf '\033c'
echo "Welcome to the arch-install script"
pacman --noconfirm -Sy archlinux-keyring
loadkeys fr
timedatectl set-ntp true && sleep 3
lsblk
echo " !! Remeber you need a root partitionand  a boot partition !! "
echo "Enter the drive: "
read drive
cfdisk $drive 
echo "Enter the linux partition: "
read partition
mkfs.ext4 $partition 
echo "Enter boot partition: "
read bootpartition
mkfs.ext4 $bootpartition
mount $partition /mnt 
mkdir /mnt/boot
mount $bootpartition /mnt/boot
pacstrap /mnt base base-devel linux linux-firmware vim nvidia
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
echo "Wich drive did you mount everything to ? [eg : sda]" 
grub-install $bootpartition
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S --noconfirm xorg-xinit noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome \
     sxiv mpv ffmpeg imagemagick fzf man-db yt-dlp xclip ntfs-3g git vim rsync firefox jq picom alacritty
sed -i 's/#%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
echo "Enter Username: "
read username
useradd -m -G wheel $username
passwd $username
cd /home/$username
git clone https://github.com/RealBlissIO/Dotfiles.git
mkdir .config
cp -r Dotfiles/config/ .config/
mv .config/config/* .config/
cp Dotfiles/.xinitrc .
cd .config/dwm/
sudo make clean install
cd ..
cd dmenu/
sudo make clean install
cd ..
cd slstatus/
sudo make clean install
cd $HOME
exit
