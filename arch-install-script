# == MY ARCH SETUP INSTALLER == #
#part1
printf '\033c'
echo "Welcome to Arch Linux Magic Script"
read -p "Do you want to automatically select the fastest mirrors? [y/n]" answer
if [[ $answer = y ]] ; then
  echo "Selecting the fastest mirrors"
  reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist --protocol https --download-timeout 5
fi
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
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
read -p "Did you also create boot partition? [y/n]" answer
if [[ $answer = y ]] ; then
  echo "Enter boot partition: "
  read bootpartition
  mkfs.ext4 $bootpartition
fi
mount $partition /mnt 
pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
sed '1,/^#part2$/d' arch_install.sh > /mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt ./arch_install2.sh
exit 

#part2
printf '\033c'
pacman -S --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
ln -sf /usr/share/zoneinfo/Africa/Algeirs /etc/localtime
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
lsblk
echo "Enter boot partition: " 
read bootpartition
mkdir /boot
mount $bootpartition /boot 
grub-install $bootpartition
sed -i 's/quiet/pci=noaer/g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S --noconfirm xorg-server xorg-xinit xorg-xkill xorg-xsetroot xorg-xbacklight xorg-xprop \
     noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome \
     sxiv mpv zathura zathura-pdf-mupdf \
     fzf man-db feh python-pywal youtube-dl xclip \
     zip unzip unrar p7zip xdotool papirus-icon-theme brightnessctl  \
     dosfstools ntfs-3g git sxhkd pipewire pipewire-pulse \
     vim arc-gtk-theme firefox \
     xcompmgr libnotify dunst slock jq \
     dhcpcd networkmanager pamixer

systemctl enable NetworkManager.service 
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
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
git clone https://git.suckless.org/dwm
git clone https://git.suckless.org/st
git clone https://git.suckless.org/dmenu
cd dwm
make clean install
cd
cd st
make clean install
cd
cd dmenu
make clean install
cd
pacman -S lightdm
systemctl enable lightdm
exit
