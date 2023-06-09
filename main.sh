#!/bin/bash

# Function to check if a command is available and install it if not
check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "The '$1' command is required but not installed. Installing..."
        sudo pacman -S --noconfirm "$1"
    fi
}

clear
echo "Hello and welcome to BlissIO's Arch install script"

# Determine the boot configuration (UEFI or BIOS)
if [ -d /sys/firmware/efi ]; then
    echo "Your PC uses UEFI"
    bcfg="uefi"
else
    echo "Your PC uses BIOS"
    bcfg="bios"
fi

# Update repositories and keyrings
echo "Updating repositories and keyrings"
sudo pacman --noconfirm -Sy archlinux-keyring

check_command "less"
layouts_dir="/usr/share/kbd/keymaps"
echo "Available Keyboard Layouts:"
ls "$layouts_dir" | less

while true; do
    read -p "Enter the desired keyboard layout (q to quit): " layout
    if [[ "$layout" == "q" ]]; then
        echo "No layout selected. Exiting."
        exit
    elif [ -e "$layouts_dir/$layout" ]; then
        loadkeys "$layout"
        echo "Keyboard layout set to $layout"
        break
    else
        echo "Invalid layout. Please try again."
    fi
done

drive_list=$(lsblk -ndo NAME,SIZE -e 7,11)
echo "Connected Drives:"
echo "$drive_list"

while true; do
    read -p "Enter the drive name to partition (e.g., /dev/sda): " drive_name
    if echo "$drive_list" | grep -q "^$drive_name"; then
        break
    else
        echo "Invalid drive name. Please try again."
    fi
done

while true; do
    read -p "Choose partitioning method - 'auto' or 'manual': " partition_method

    if [[ "$partition_method" == "auto" ]]; then
        echo "Performing automatic partitioning..."
	if [[ "$bcfg" == "bios" ]]; then
            parted "$drive_name" mklabel msdos
            parted "$drive_name" mkpart primary ext4 1MiB 513MiB
            parted "$drive_name" set 1 boot on
            parted "$drive_name" mkpart primary linux-swap 513MiB 100%
            parted "$drive_name" mkpart primary ext4 100% 100%
        elif [[ "$bcfg" == "uefi" ]]; then
            parted "$drive_name" mklabel gpt
            parted "$drive_name" mkpart primary fat32 1MiB 701MiB
            parted "$drive_name" set 1 esp on
            parted "$drive_name" mkpart primary linux-swap 701MiB 100%
            parted "$drive_name" mkpart primary ext4 100% 100%
        fi
        
        mkfs.ext4 "${drive_name}1"
        mkswap "${drive_name}2"
        mkfs.ext4 "${drive_name}3"
        
        echo "Automatic partitioning completed."
        break
    elif [[ "$partition_method" == "manual" ]]; then
        echo "Performing manual partitioning..."
        echo "Please partition the drive manually using 'cfdisk' or another tool."
        echo "Once the partitions are created, format them using appropriate filesystems."
        
        read -p "Press Enter to continue after partitioning and formatting are done"
        read -p "Enter the root partition (e.g., ${drive_name}1): " root_partition
        mkfs.ext4 "$root_partition"
        if [[ "$bcfg" == "bios" ]]; then
            read -p "Enter the boot partition (e.g., ${drive_name}2): " boot_partition
            mkfs.ext4 "$boot_partition"
            
            read -p "Enter the swap partition (e.g., ${drive_name}3): " swap_partition
            mkswap "$swap_partition"
            swapon "$swap_partition"
            
            read -p "Enter the home partition (optional, leave empty if not needed): " home_partition
            if [[ -n "$home_partition" ]]; then
                mkfs.ext4 "$home_partition"
            fi
        elif [[ "$bcfg" == "uefi" ]]; then
            read -p "Enter the EFI partition (e.g., ${drive_name}2): " efi_partition
            mkfs.fat -F32 "$efi_partition"
            
            read -p "Enter the swap partition (e.g., ${drive_name}3): " swap_partition
            mkswap "$swap_partition"
            swapon "$swap_partition"
            
            read -p "Enter the home partition (optional, leave empty if not needed): " home_partition
            if [[ -n "$home_partition" ]]; then
                mkfs.ext4 "$home_partition"
            fi
        fi
        
        echo "Manual partitioning completed."
	break
    else
        echo "Invalid option. Please choose 'auto' or 'manual'."
    fi
done

read -p "Press Enter to continue with pacstrap..."
echo "Installing base packages..."
if [[ "$bcfg" == "bios" ]]; then
    pacstrap /mnt base base-devel linux linux-firmware
elif [[ "$bcfg" == "uefi" ]]; then
    pacstrap /mnt base base-devel linux linux-firmware efibootmgr
fi

echo "Detecting and installing additional drivers/packages..."
#if the use of an NVIDIA GPU is detected we install NVIDIA drivers 
if lspci | grep -i NVIDIA &>/dev/null; then
    echo "NVIDIA GPU detected. Installing NVIDIA drivers..."
    pacstrap /mnt nvidia
fi
# if Broadcom wireless card is detected we install Broadcom wireless drivers
if lspci | grep -i broadcom &>/dev/null || lspci | grep -i bcm &>/dev/null; then
    echo "Broadcom wireless card detected. Installing Broadcom drivers..."
    pacstrap /mnt broadcom-wl
fi
echo "pacstrap completed."


genfstab -U /mnt >> /mnt/etc/fstab
echo "Chrooting into the installed environment..."
arch-chroot /mnt /bin/bash <<EOF
# Set up locales
echo "Setting up locales..."
echo "Please select the desired locale from the list below:"
locale_list=$(grep -oP '^#\s\K.*$' /etc/locale.gen)
echo "$locale_list" | less
while true; do
    read -p "Enter the desired locale (q to quit): " locale
    if [[ "$locale" == "q" ]]; then
        echo "No locale selected. Exiting."
        exit
    elif echo "$locale_list" | grep -q "^$locale$"; then
        sed -i "s/#$locale/$locale/" /etc/locale.gen
        locale-gen
        echo "LANG=$locale.UTF-8" > /etc/locale.conf
        export LANG=$locale.UTF-8
        echo "Locale set to $locale.UTF-8"
        break
    else
        echo "Invalid locale. Please try again."
    fi
done

# Set up localtime
echo "Setting up localtime..."
ln -sf /usr/share/zoneinfo/$(tzselect) /etc/localtime
hwclock --systohc

# Set hostname
read -p "Enter the desired hostname: " hostname
echo "$hostname" > /etc/hostname

# Generate mkinitcpio
echo "Generating mkinitcpio..."
mkinitcpio -P

# Install bootloader
if [[ "$bcfg" == "bios" ]]; then
    echo "Installing GRUB..."
    pacman --noconfirm -S grub
    grub-install --target=i386-pc "$drive_name"
    grub-mkconfig -o /boot/grub/grub.cfg
elif [[ "$bcfg" == "uefi" ]]; then
    echo "Installing EFISTUB..."
    pacman --noconfirm -S efibootmgr
    efibootmgr --create --disk "$drive_name" --part 1 --loader /vmlinuz-linux --label "Arch Linux" --unicode 'root=PARTUUID=$(blkid -s PARTUUID -o value "$drive_name"3) rw initrd=\initramfs-linux.img' --verbose
fi

# Set root password
echo "Setting root password..."
passwd

# Create a user
read -p "Enter the username for the new user: " username
useradd -m -G wheel -s /bin/bash "$username"
echo "Setting password for user $username..."
passwd "$username"

# Configure sudo
echo "Configuring sudo..."
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Install and configure desktop environment
echo "Install a desktop environment: xfce, gnome, kde, or none?"
read -p "Enter your choice (xfce/gnome/kde/none): " desktop_env

if [[ "$desktop_env" == "xfce" ]]; then
    echo "Installing XFCE..."
    pacman --noconfirm -S xfce4 xfce4-goodies
elif [[ "$desktop_env" == "gnome" ]]; then
    echo "Installing GNOME..."
    pacman --noconfirm -S gnome
elif [[ "$desktop_env" == "kde" ]]; then
    echo "Installing KDE..."
    pacman --noconfirm -S plasma kde-applications
elif [[ "$desktop_env" == "none" ]]; then
    echo "Installing NetworkManager..."
    pacman --noconfirm -S networkmanager
    systemctl enable NetworkManager
fi

echo "Installation and configuration completed. Exiting chroot."
EOF
echo "Installation and configuration completed successfully!"
