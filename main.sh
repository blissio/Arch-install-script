#!/bin/bash

# Enhanced Arch Linux Installation Script with Gaming Setup
# Supports NVIDIA/AMD/Intel GPU detection
# Uses systemd-boot for UEFI, GRUB for BIOS
# Enhanced error handling for network/mirror issues

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check internet connectivity
check_internet() {
    print_info "Checking internet connectivity..."
    if ! ping -c 3 archlinux.org &>/dev/null; then
        print_error "No internet connection. Please check your network."
        return 1
    fi
    print_success "Internet connection available"
    return 0
}

# Function to update mirrorlist with reliable mirrors
update_mirrorlist() {
    print_info "Updating mirrorlist for better download speeds..."
    
    # Backup current mirrorlist
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup 2>/dev/null || true
    
    # Install reflector if not available
    if ! command -v reflector &>/dev/null; then
        print_info "Installing reflector for mirror optimization..."
        pacman --noconfirm -Sy reflector
    fi
    
    # Generate optimized mirrorlist
    print_info "Generating optimized mirrorlist..."
    reflector \
        --country "$(curl -s https://ipapi.co/country/ 2>/dev/null || echo US)" \
        --protocol https \
        --latest 20 \
        --sort rate \
        --save /etc/pacman.d/mirrorlist \
        --connection-timeout 5 \
        --download-timeout 10
    
    print_success "Mirrorlist updated"
}

# Function to retry package operations with better error handling
pacman_retry() {
    local max_retries=3
    local retry_delay=10
    local attempt=1
    
    while [ $attempt -le $max_retries ]; do
        print_info "Attempt $attempt of $max_retries: $*"
        
        if pacman "$@"; then
            return 0
        fi
        
        print_warning "Attempt $attempt failed, retrying in $retry_delay seconds..."
        sleep $retry_delay
        
        # Increase retry delay for subsequent attempts
        retry_delay=$((retry_delay * 2))
        ((attempt++))
    done
    
    print_error "All $max_retries attempts failed for: $*"
    return 1
}

# Function to install packages with robust error handling
install_packages() {
    local package_list="$*"
    local max_retries=3
    local attempt=1
    
    print_info "Installing packages: $package_list"
    
    while [ $attempt -le $max_retries ]; do
        print_info "Package installation attempt $attempt of $max_retries"
        
        # Use parallel downloads and continue on error to get as many packages as possible
        if pacstrap -c /mnt $package_list 2>&1 | tee /tmp/pacstrap.log; then
            print_success "Package installation completed successfully"
            return 0
        fi
        
        # Check if we had critical failures vs. just some package failures
        if grep -q "failed to commit transaction" /tmp/pacstrap.log; then
            print_warning "Some packages failed to install, checking which ones..."
            
            # Extract failed package names from the log
            local failed_packages=$(grep -o "failed retrieving file .*" /tmp/pacstrap.log | sed "s/failed retrieving file '\(.*\)'.*/\1/" | grep -o '^[^-]*' | sort -u)
            
            if [ -n "$failed_packages" ]; then
                print_warning "Failed packages: $failed_packages"
                
                # Try installing remaining packages individually
                local remaining_packages="$package_list"
                for failed_pkg in $failed_packages; do
                    print_warning "Skipping problematic package: $failed_pkg"
                    remaining_packages=$(echo "$remaining_packages" | sed "s/\b$failed_pkg\b//g")
                done
                
                if [ -n "$remaining_packages" ]; then
                    print_info "Retrying with remaining packages: $remaining_packages"
                    package_list="$remaining_packages"
                else
                    print_error "All packages failed to install"
                    return 1
                fi
            fi
        fi
        
        if [ $attempt -lt $max_retries ]; then
            print_warning "Attempt $attempt failed, updating mirrors and retrying..."
            update_mirrorlist
            print_info "Waiting before retry..."
            sleep 10
        fi
        
        ((attempt++))
    done
    
    print_error "Failed to install packages after $max_retries attempts"
    return 1
}

# Function to check if a command is available
check_command() {
    if ! command -v "$1" &>/dev/null; then
        print_info "Installing required command: $1"
        pacman_retry -S --noconfirm "$1"
    fi
}

clear
echo "=========================================="
echo "  Arch Linux Gaming Setup Installer"
echo "=========================================="
echo ""

# Check internet first
if ! check_internet; then
    print_error "Cannot proceed without internet connection"
    exit 1
fi

# Update mirrorlist for better performance
update_mirrorlist

# Update system clock
timedatectl set-ntp true

# Update repositories and keyrings with retry mechanism
print_info "Updating repositories and keyrings..."
pacman_retry --noconfirm -Sy archlinux-keyring

# Detect boot mode
if [ -d /sys/firmware/efi ]; then
    BOOT_MODE="uefi"
    print_success "Detected UEFI boot mode - will use systemd-boot"
else
    BOOT_MODE="bios"
    print_success "Detected BIOS/Legacy boot mode - will use GRUB"
fi

# Detect GPU
print_info "Detecting GPU..."
GPU_TYPE="unknown"

if lspci | grep -i "VGA" | grep -i "NVIDIA" &>/dev/null; then
    GPU_TYPE="nvidia"
    print_success "NVIDIA GPU detected"
elif lspci | grep -i "VGA" | grep -i "AMD\|ATI" &>/dev/null; then
    GPU_TYPE="amd"
    print_success "AMD GPU detected"
elif lspci | grep -i "VGA" | grep -i "Intel" &>/dev/null; then
    GPU_TYPE="intel"
    print_success "Intel GPU detected"
else
    print_warning "Could not detect GPU type"
fi

# Keyboard layout selection
check_command "less"
print_info "Setting keyboard layout..."
echo ""
echo "Available keyboard layouts:"
localectl list-keymaps | less

while true; do
    read -p "Enter keyboard layout (default: us): " KEYMAP
    KEYMAP=${KEYMAP:-us}
    if localectl list-keymaps | grep -q "^${KEYMAP}$"; then
        loadkeys "$KEYMAP"
        print_success "Keyboard layout set to $KEYMAP"
        break
    else
        print_error "Invalid layout. Please try again."
    fi
done

# Disk selection
print_info "Available drives:"
lsblk -ndo NAME,SIZE,TYPE | grep disk
echo ""

while true; do
    read -p "Enter the drive to install Arch (e.g., sda, nvme0n1): " DRIVE_NAME
    DRIVE_PATH="/dev/${DRIVE_NAME}"
    
    if [ -b "$DRIVE_PATH" ]; then
        print_warning "WARNING: All data on $DRIVE_PATH will be erased!"
        read -p "Are you sure? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            break
        fi
    else
        print_error "Invalid drive name. Please try again."
    fi
done

# Partitioning
print_info "Starting automatic partitioning for $BOOT_MODE..."

# Determine partition naming scheme
if [[ "$DRIVE_NAME" == nvme* ]] || [[ "$DRIVE_NAME" == mmcblk* ]]; then
    PART_PREFIX="${DRIVE_PATH}p"
else
    PART_PREFIX="${DRIVE_PATH}"
fi

# Wipe existing partition table
wipefs -af "$DRIVE_PATH"
sgdisk -Z "$DRIVE_PATH" 2>/dev/null || true

if [[ "$BOOT_MODE" == "uefi" ]]; then
    print_info "Creating GPT partition table for UEFI..."
    parted -s "$DRIVE_PATH" mklabel gpt
    parted -s "$DRIVE_PATH" mkpart primary fat32 1MiB 1GiB
    parted -s "$DRIVE_PATH" set 1 esp on
    parted -s "$DRIVE_PATH" mkpart primary linux-swap 1GiB 17GiB
    parted -s "$DRIVE_PATH" mkpart primary ext4 17GiB 100%
    
    BOOT_PART="${PART_PREFIX}1"
    SWAP_PART="${PART_PREFIX}2"
    ROOT_PART="${PART_PREFIX}3"
    
    print_info "Formatting partitions..."
    mkfs.fat -F32 "$BOOT_PART"
    mkswap "$SWAP_PART"
    mkfs.ext4 -F "$ROOT_PART"
    
else
    print_info "Creating MBR partition table for BIOS..."
    parted -s "$DRIVE_PATH" mklabel msdos
    parted -s "$DRIVE_PATH" mkpart primary ext4 1MiB 513MiB
    parted -s "$DRIVE_PATH" set 1 boot on
    parted -s "$DRIVE_PATH" mkpart primary linux-swap 513MiB 16GiB
    parted -s "$DRIVE_PATH" mkpart primary ext4 16GiB 100%
    
    BOOT_PART="${PART_PREFIX}1"
    SWAP_PART="${PART_PREFIX}2"
    ROOT_PART="${PART_PREFIX}3"
    
    print_info "Formatting partitions..."
    mkfs.ext4 -F "$BOOT_PART"
    mkswap "$SWAP_PART"
    mkfs.ext4 -F "$ROOT_PART"
fi

# Mount partitions
print_info "Mounting partitions..."
swapon "$SWAP_PART"
mount "$ROOT_PART" /mnt

if [[ "$BOOT_MODE" == "uefi" ]]; then
    mkdir -p /mnt/boot
    mount "$BOOT_PART" /mnt/boot
else
    mkdir -p /mnt/boot
    mount "$BOOT_PART" /mnt/boot
fi

print_success "Partitioning completed"

# Install base system with enhanced error handling
print_info "Installing base system (this may take a while)..."

BASE_PACKAGES="base base-devel linux linux-firmware linux-headers"
SYSTEM_PACKAGES="networkmanager network-manager-applet wireless_tools wpa_supplicant dialog os-prober mtools dosfstools git wget curl nano vim"
AUDIO_PACKAGES="pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber"
FILESYSTEM_PACKAGES="ntfs-3g exfat-utils gvfs gvfs-mtp udisks2"

if ! install_packages $BASE_PACKAGES $SYSTEM_PACKAGES $AUDIO_PACKAGES $FILESYSTEM_PACKAGES; then
    print_error "Critical package installation failed"
    print_info "You may need to check your internet connection or try different mirrors"
    exit 1
fi

# Install bootloader packages
if [[ "$BOOT_MODE" == "uefi" ]]; then
    pacman_retry -S --noconfirm efibootmgr
else
    pacman_retry -S --noconfirm grub
fi

# Install GPU drivers (64-bit only for now)
print_info "Installing GPU drivers..."
case "$GPU_TYPE" in
    nvidia)
        print_info "Installing NVIDIA drivers..."
        pacman_retry -S --noconfirm nvidia nvidia-utils nvidia-settings
        ;;
    amd)
        print_info "Installing AMD drivers..."
        pacman_retry -S --noconfirm mesa vulkan-radeon libva-mesa-driver mesa-vdpau
        ;;
    intel)
        print_info "Installing Intel drivers..."
        pacman_retry -S --noconfirm mesa vulkan-intel libva-intel-driver intel-media-driver
        ;;
    *)
        print_warning "Installing generic GPU drivers..."
        pacman_retry -S --noconfirm mesa
        ;;
esac

# Install KDE Plasma
print_info "Installing KDE Plasma..."
KDE_PACKAGES="plasma-meta kde-applications-meta sddm"
pacman_retry -S --noconfirm $KDE_PACKAGES

# Additional useful packages
print_info "Installing additional packages..."
EXTRA_PACKAGES="firefox discord qt5-virtualkeyboard dnsmasq vde2 bridge-utils openbsd-netcat ebtables"
pacman_retry -S --noconfirm $EXTRA_PACKAGES

# Generate fstab
print_info "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Get ROOT_PARTUUID for systemd-boot
if [[ "$BOOT_MODE" == "uefi" ]]; then
    ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PART")
fi

# Chroot and configure system
print_info "Configuring system in chroot..."

arch-chroot /mnt /bin/bash <<CHROOT_EOF
set -e

# Set timezone
echo "Select timezone:"
ln -sf /usr/share/zoneinfo/\$(tzselect) /etc/localtime
hwclock --systohc

# Locale configuration
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# Network configuration
read -p "Enter hostname: " HOSTNAME
echo "\$HOSTNAME" > /etc/hostname

cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   \$HOSTNAME.localdomain \$HOSTNAME
EOF

# Install bootloader
if [[ "$BOOT_MODE" == "uefi" ]]; then
    echo "Installing systemd-boot..."
    bootctl --path=/boot install
    
    cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout 3
console-mode max
editor no
EOF
    
    cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=${ROOT_PARTUUID} rw
EOF

    # NVIDIA-specific boot parameters
    if [[ "$GPU_TYPE" == "nvidia" ]]; then
        sed -i 's/rw$/rw nvidia-drm.modeset=1/' /boot/loader/entries/arch.conf
    fi
else
    echo "Installing GRUB..."
    grub-install --target=i386-pc "$DRIVE_PATH"
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# Initramfs
mkinitcpio -P

# Enable services
systemctl enable NetworkManager
systemctl enable sddm
systemctl enable udisks2

# Create user
read -p "Enter username: " USERNAME
useradd -m -G wheel,storage,power,audio,video,input,optical -s /bin/bash "\$USERNAME"

echo "Set password for \$USERNAME:"
passwd "\$USERNAME"

echo "Set root password:"
passwd

# Configure sudo
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable multilib for 32-bit support
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Sy

# Gaming optimizations
echo "Applying gaming optimizations..."

# Gamemode configuration
cat > /etc/security/limits.conf <<EOF
\$USERNAME    soft    nofile  524288
\$USERNAME    hard    nofile  524288
EOF

# Add user to gamemode group
usermod -aG gamemode "\$USERNAME"

# Configure automatic NTFS mounting
echo "Configuring automatic NTFS drive mounting..."
mkdir -p /etc/udev/rules.d

# Detect and auto-mount NTFS partitions
echo "Detecting existing NTFS partitions..."
NTFS_PARTS=\$(blkid -t TYPE=ntfs -o device)

if [ -n "\$NTFS_PARTS" ]; then
    echo "Found NTFS partitions. Adding to fstab for auto-mounting..."
    
    for NTFS_PART in \$NTFS_PARTS; do
        # Skip if it's our root or boot partition
        if [[ "\$NTFS_PART" == "$ROOT_PART" ]] || [[ "\$NTFS_PART" == "$BOOT_PART" ]] || [[ "\$NTFS_PART" == "$SWAP_PART" ]]; then
            continue
        fi
        
        # Get UUID and create mount point
        PART_UUID=\$(blkid -s UUID -o value "\$NTFS_PART")
        PART_LABEL=\$(blkid -s LABEL -o value "\$NTFS_PART" 2>/dev/null)
        
        if [ -z "\$PART_LABEL" ]; then
            MOUNT_NAME="ntfs_\${PART_UUID:0:8}"
        else
            # Clean label for use as directory name
            MOUNT_NAME=\$(echo "\$PART_LABEL" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
        fi
        
        MOUNT_POINT="/mnt/\$MOUNT_NAME"
        mkdir -p "\$MOUNT_POINT"
        chown \$USERNAME:\$USERNAME "\$MOUNT_POINT"
        
        # Add to fstab with proper NTFS-3G options
        echo "# NTFS partition \$NTFS_PART" >> /etc/fstab
        echo "UUID=\$PART_UUID \$MOUNT_POINT ntfs-3g defaults,uid=1000,gid=1000,dmask=022,fmask=133,windows_names 0 0" >> /etc/fstab
        
        echo "  Added \$NTFS_PART to fstab (will mount at \$MOUNT_POINT)"
    done
else
    echo "No existing NTFS partitions detected."
fi

echo "NTFS support configured. KDE will auto-mount external NTFS drives via udisks2."

# NVIDIA-specific configurations
if [[ "$GPU_TYPE" == "nvidia" ]]; then
    echo "Configuring NVIDIA..."
    echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia.conf
fi

echo "Installation complete!"
CHROOT_EOF

print_success "=========================================="
print_success "  Installation completed successfully!"
print_success "=========================================="
echo ""
print_info "You can now:"
print_info "1. Type 'reboot' to restart"
print_info "2. Remove installation media"
print_info ""
print_info "Post-installation tips:"
print_info "- Steam: Enable Proton in Steam settings for Windows games"
print_info "- Lutris: Use for non-Steam games"
print_info "- Launch games with: gamemoderun %command%"
print_info "- Monitor performance with MangoHud"
print_info "- NTFS drives will auto-mount in KDE file manager"
print_info "- Existing NTFS partitions mounted under /mnt/"
echo ""

read -p "Press Enter to exit..."