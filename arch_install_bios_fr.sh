# == MY ARCH SETUP INSTALLER == #
#part1
printf '\033c'
echo "Welcome to shaolin's arch installer script"
read -p "This installer is for BIOS/Legacy computers. Do you wish to continue? [y/n]" answer
if [[ $answer = n ]] ; then
  echo "Installer offline"
  exit 1
fi
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 3/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
loadkeys fr
timedatectl set-ntp true
lsblk
echo "Enter the drive [ex: /dev/sda]: "
read drive
cfdisk $drive 
echo "Enter the root partition [ex: /dev/sda]: "
read partition
mkfs.ext4 $partition 
mount $partition /mnt 
read -p "Did you also create a boot partition? [y/n]" answer
if [[ $answer = y ]] ; then
  echo "Enter boot partition: "
  read bootpartition
  mkfs.ext4 $bootpartition
  mkdir /mnt/boot
  mount $bootpartition /mnt/boot
fi
read -p "Did you also create a swap partition? [y/n]" answer
if [[ $answer = y ]] ; then
  echo "Enter swap partition: "
  read swappartition
  mkswap $swappartition
  swapon $swappartition
fi
read -p "Did you also create a home partition? [y/n]" answer
if [[ $answer = y ]] ; then
  echo "Enter home partition: "
  read homepartition
  mkfs.ext4 $homepartition 
  mkdir /mnt/home
  mount $homepartition /mnt/home
fi
pacstrap /mnt base base-devel linux linux-firmware nvidia nvidia-firmware
genfstab -U /mnt >> /mnt/etc/fstab
sed '1,/^#part2$/d' `basename $0` > /mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt ./arch_install2.sh
exit 

#part2
printf '\033c'
pacman -S --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 3/" /etc/pacman.conf
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
pacman --noconfirm -S grub os-prober
clear
lsblk
echo "Enter the drive [ex: /dev/sda]: "
read drive
grub-install $drive
sed -i 's/quiet/pci=noaer/g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S --noconfirm xorg-server xorg-xinit xorg-xkill xorg-xsetroot xorg-xbacklight xorg-xprop \
     noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome \
     sxiv mpv zathura zathura-pdf-mupdf ffmpeg imagemagick  \
     fzf man-db nitrogen python-pywal unclutter xclip maim \
     zip unzip unrar p7zip xdotool papirus-icon-theme brightnessctl  \
     dosfstools ntfs-3g git pipewire pipewire-pulse \
     arc-gtk-theme rsync firefox \
     picom libnotify dunst slock jq aria2 cowsay \
     networkmanager wpa_supplicant rsync pamixer cmus mpd ncmpcpp \
     libconfig polybar

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
mkdir .config
cd .config/
# pikaur: AUR helper
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -fsri
cd
pikaur -S libxft-bgra-git yt-dlp-drop-in
cd 
mkdir dw fi
ln -s ~/.config/x11/xinitrc .xinitrc
exit
