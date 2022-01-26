# == MY ARCH SETUP INSTALLER == #
#part1
printf '\033c'
echo "Welcome to the arch-install script"
reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist --protocol https --download-timeout 5
pacman --noconfirm -Sy archlinux-keyring
loadkeys fr
timedatectl set-ntp true
lsblk
echo "Enter the drive: "
read drive
cfdisk $drive 
echo "Enter the linux partition: "
read partition
mkfs.ext4 $partition 
echo "Enter boot partition: "
read bootpartition
mkfs.ext4 $bootpartition
echo "Enter home partition: "
read homepartition
mkfs.ext4 $homepartition
mount $partition /mnt 
mkdir /mnt/boot
mkdir /mnt/home
mount $bootpartition /mnt/boot
mount $homepartition /mnt/home
pacstrap /mnt base base-devel linux linux-firmware vim nvidia
genfstab -U /mnt >> /mnt/etc/fstab
sed '1,/^#part2$/d' arch_install.sh > /mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt ./arch_install2.sh
exit 

#part2
printf '\033c'
pacman -S --noconfirm sed
ln -sf /usr/share/zoneinfo/Africa/Algiers /etc/localtime
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
echo "Enter boot partition: " 
grub-install $bootpartition
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S --noconfirm xorg-xinit \
     noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome \
     sxiv mpv ffmpeg imagemagick  \
     fzf man-db youtube-dl xclip maim \
     zip unzip unrar p7zip xdotool papirus-icon-theme  \
     ntfs-3g git pipewire pipewire-pulse \
     vim arc-gtk-theme rsync firefox \
     xcompmgr libnotify jq \
     dhcpcd rsync picom
sed -i 's/#%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
echo "Enter Username: "
read username
useradd -m -G wheel $username
passwd $username
echo "Pre-Installation Finish Reboot now"
ai3_path=/home/$username/arch_install3.sh
sed '1,/^#part3$/d' arch_install2.sh > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/sh $username
exit 

#part3
printf '\033c'
cd $HOME

exit
