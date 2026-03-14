#!/bin/bash

# Arch Linux Installation Script
# Supports NVIDIA/AMD/Intel GPU detection
# Uses systemd-boot for UEFI, GRUB for BIOS
# DE selection: KDE, GNOME, XFCE
# Optional gaming setup, AUR helper, configurable swap

set -e

# #########################################
# COLORS & LOGGING
# #########################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# #########################################
# ERROR HANDLING
# #########################################
handle_error() {
    local exit_code=$?
    local line_number=$1
    print_error "Script failed at line $line_number with exit code $exit_code"
    print_error "Check the output above for details"
    exit $exit_code
}

trap 'handle_error $LINENO' ERR

# #########################################
# PACKAGE HELPERS
# #########################################
pacman_retry() {
    local max_retries=3
    local retry_delay=5
    local attempt=1

    while [ $attempt -le $max_retries ]; do
        print_info "Attempt $attempt of $max_retries: pacman $*"
        if pacman "$@"; then
            return 0
        fi
        if [ $attempt -lt $max_retries ]; then
            print_warning "Attempt $attempt failed, retrying in ${retry_delay}s..."
            sleep $retry_delay
        fi
        ((attempt++))
    done

    print_error "All $max_retries attempts failed for: pacman $*"
    return 1
}

install_packages() {
    local package_list="$*"
    local max_retries=3
    local attempt=1

    print_info "Installing: $package_list"

    while [ $attempt -le $max_retries ]; do
        print_info "Attempt $attempt of $max_retries..."
        if pacstrap -c /mnt $package_list; then
            print_success "Packages installed successfully"
            return 0
        fi
        if [ $attempt -lt $max_retries ]; then
            print_warning "Attempt $attempt failed, retrying in 5s..."
            sleep 5
        fi
        ((attempt++))
    done

    print_error "Failed to install packages after $max_retries attempts"
    print_warning "Continuing with partial installation..."
    return 1
}

check_command() {
    if ! command -v "$1" &>/dev/null; then
        print_info "Installing required command: $1"
        pacman_retry -S --noconfirm "$1"
    fi
}

# #########################################
# CHECKS
# #########################################
clear
echo "=========================================="
echo "     Arch Linux Installer by blissio"
echo "=========================================="
echo ""

# Must run as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

# Check internet connectivity
print_info "Checking internet connection..."
if ! ping -c 1 archlinux.org &>/dev/null; then
    print_error "No internet connection detected. Please connect and try again."
    exit 1
fi
print_success "Internet connection confirmed"

# Update system clock
timedatectl set-ntp true

# Update repos and keyrings
print_info "Updating repositories and keyrings..."
pacman_retry --noconfirm -Sy archlinux-keyring

# #########################################
# BOOT MODE DETECTION
# #########################################
if [ -d /sys/firmware/efi ]; then
    BOOT_MODE="uefi"
    print_success "UEFI detected — will use systemd-boot"
else
    BOOT_MODE="bios"
    print_success "BIOS/Legacy detected — will use GRUB"
fi

# #########################################
# GPU DETECTION
# #########################################
print_info "Detecting GPU..."
GPU_TYPE="unknown"

if lspci | grep -i "VGA" | grep -qi "NVIDIA"; then
    GPU_TYPE="nvidia"
    print_success "NVIDIA GPU detected"
elif lspci | grep -i "VGA" | grep -qiE "AMD|ATI"; then
    GPU_TYPE="amd"
    print_success "AMD GPU detected"
elif lspci | grep -i "VGA" | grep -qi "Intel"; then
    GPU_TYPE="intel"
    print_success "Intel GPU detected"
else
    print_warning "GPU type could not be detected — will install mesa fallback"
fi

# #########################################
# USER PROMPTS
# #########################################

# Keyboard layout
check_command "less"
print_info "Available keyboard layouts (press q to exit list):"
localectl list-keymaps | less

while true; do
    read -rp "Enter keyboard layout (default: us): " KEYMAP
    KEYMAP=${KEYMAP:-us}
    if localectl list-keymaps | grep -q "^${KEYMAP}$"; then
        loadkeys "$KEYMAP"
        print_success "Keyboard layout set to $KEYMAP"
        break
    else
        print_error "Invalid layout '$KEYMAP'. Please try again."
    fi
done

# Hostname
while true; do
    read -rp "Enter hostname: " HOSTNAME
    if [[ "$HOSTNAME" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; then
        break
    else
        print_error "Invalid hostname. Use letters, numbers, and hyphens only."
    fi
done

# Username
while true; do
    read -rp "Enter username: " USERNAME
    if [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        break
    else
        print_error "Invalid username. Use lowercase letters, numbers, hyphens, underscores."
    fi
done

# Swap size
while true; do
    read -rp "Enter swap file size in GB (e.g. 8, 16): " SWAP_SIZE
    if [[ "$SWAP_SIZE" =~ ^[0-9]+$ ]] && [ "$SWAP_SIZE" -gt 0 ]; then
        SWAP_MB=$((SWAP_SIZE * 1024))
        print_success "Swap file will be ${SWAP_SIZE}GB"
        break
    else
        print_error "Please enter a valid number greater than 0."
    fi
done

# Desktop environment
echo ""
echo "Select a Desktop Environment:"
echo "  1) KDE Plasma"
echo "  2) GNOME"
echo "  3) XFCE"
echo "  4) None (minimal install)"
echo ""

while true; do
    read -rp "Enter choice [1-4]: " DE_CHOICE
    case $DE_CHOICE in
        1) DE="kde";   print_success "KDE Plasma selected";  break ;;
        2) DE="gnome"; print_success "GNOME selected";       break ;;
        3) DE="xfce";  print_success "XFCE selected";        break ;;
        4) DE="none";  print_success "Minimal install selected"; break ;;
        *) print_error "Invalid choice. Enter 1, 2, 3, or 4." ;;
    esac
done

# AUR helper
echo ""
echo "Select an AUR helper to install:"
echo "  1) paru (recommended)"
echo "  2) yay"
echo "  3) None"
echo ""

while true; do
    read -rp "Enter choice [1-3]: " AUR_CHOICE
    case $AUR_CHOICE in
        1) AUR_HELPER="paru"; print_success "paru selected"; break ;;
        2) AUR_HELPER="yay";  print_success "yay selected";  break ;;
        3) AUR_HELPER="none"; print_success "No AUR helper"; break ;;
        *) print_error "Invalid choice." ;;
    esac
done

# Gaming setup
echo ""
read -rp "Install gaming setup? (Steam, gamemode, MangoHud, Lutris) [y/N]: " GAMING_CHOICE
if [[ "$GAMING_CHOICE" =~ ^[Yy]$ ]]; then
    INSTALL_GAMING=true
    print_success "Gaming setup will be installed"
else
    INSTALL_GAMING=false
    print_info "Skipping gaming setup"
fi

# #########################################
# DISK SELECTION & PARTITIONING
# #########################################
print_info "Available drives:"
lsblk -ndo NAME,SIZE,TYPE | grep disk
echo ""

while true; do
    read -rp "Enter the drive to install Arch (e.g. sda, nvme0n1): " DRIVE_NAME
    DRIVE_PATH="/dev/${DRIVE_NAME}"

    if [ ! -b "$DRIVE_PATH" ]; then
        print_error "Drive $DRIVE_PATH not found. Try again."
        continue
    fi

    print_warning "WARNING: ALL data on $DRIVE_PATH will be erased!"
    lsblk "$DRIVE_PATH"
    echo ""
    read -rp "Type 'yes' to confirm: " confirm
    [[ "$confirm" == "yes" ]] && break
    print_info "Cancelled. Please select a drive."
done

# Partition naming
if [[ "$DRIVE_NAME" == nvme* ]] || [[ "$DRIVE_NAME" == mmcblk* ]]; then
    PART_PREFIX="${DRIVE_PATH}p"
else
    PART_PREFIX="${DRIVE_PATH}"
fi

# Wipe and partition
print_info "Wiping existing partition table..."
wipefs -af "$DRIVE_PATH"
sgdisk -Z "$DRIVE_PATH" 2>/dev/null || true

if [[ "$BOOT_MODE" == "uefi" ]]; then
    print_info "Creating GPT partition table for UEFI..."
    parted -s "$DRIVE_PATH" mklabel gpt
    parted -s "$DRIVE_PATH" mkpart primary fat32 1MiB 1GiB
    parted -s "$DRIVE_PATH" set 1 esp on
    parted -s "$DRIVE_PATH" mkpart primary ext4 1GiB 100%

    BOOT_PART="${PART_PREFIX}1"
    ROOT_PART="${PART_PREFIX}2"

    mkfs.fat -F32 "$BOOT_PART"
    mkfs.ext4 -F "$ROOT_PART"
else
    print_info "Creating MBR partition table for BIOS..."
    parted -s "$DRIVE_PATH" mklabel msdos
    parted -s "$DRIVE_PATH" mkpart primary ext4 1MiB 513MiB
    parted -s "$DRIVE_PATH" set 1 boot on
    parted -s "$DRIVE_PATH" mkpart primary ext4 513MiB 100%

    BOOT_PART="${PART_PREFIX}1"
    ROOT_PART="${PART_PREFIX}2"

    mkfs.ext4 -F "$BOOT_PART"
    mkfs.ext4 -F "$ROOT_PART"
fi

# Mount
print_info "Mounting partitions..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$BOOT_PART" /mnt/boot
print_success "Partitions mounted"

# #########################################
# BASE INSTALL
# #########################################
BASE_PACKAGES="base base-devel linux linux-firmware linux-headers"
SYSTEM_PACKAGES="networkmanager network-manager-applet wireless_tools wpa_supplicant dialog os-prober mtools dosfstools git wget curl nano vim"
AUDIO_PACKAGES="pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber"
FILESYSTEM_PACKAGES="ntfs-3g exfat-utils gvfs gvfs-mtp udisks2"

install_packages $BASE_PACKAGES $SYSTEM_PACKAGES $AUDIO_PACKAGES $FILESYSTEM_PACKAGES || true

# Bootloader packages
if [[ "$BOOT_MODE" == "uefi" ]]; then
    pacman_retry -S --noconfirm efibootmgr
else
    pacman_retry -S --noconfirm grub
fi

# GPU drivers
print_info "Installing GPU drivers..."
case "$GPU_TYPE" in
    nvidia) pacman_retry -S --noconfirm nvidia nvidia-utils nvidia-settings ;;
    amd)    pacman_retry -S --noconfirm mesa vulkan-radeon libva-mesa-driver mesa-vdpau ;;
    intel)  pacman_retry -S --noconfirm mesa vulkan-intel libva-intel-driver intel-media-driver ;;
    *)      pacman_retry -S --noconfirm mesa ;;
esac

# Desktop environment
case "$DE" in
    kde)
        print_info "Installing KDE Plasma..."
        pacman_retry -S --noconfirm plasma-meta kde-applications-meta sddm || true
        DE_SERVICE="sddm"
        ;;
    gnome)
        print_info "Installing GNOME..."
        pacman_retry -S --noconfirm gnome gnome-extra gdm || true
        DE_SERVICE="gdm"
        ;;
    xfce)
        print_info "Installing XFCE..."
        pacman_retry -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter || true
        DE_SERVICE="lightdm"
        ;;
    none)
        print_info "Skipping DE install"
        DE_SERVICE=""
        ;;
esac

# Gaming packages
if [ "$INSTALL_GAMING" = true ]; then
    print_info "Installing gaming packages..."
    # Enable multilib first
    sed -i '/\[multilib\]/,/Include/s/^#//' /mnt/etc/pacman.conf
    pacman_retry -S --noconfirm steam gamemode lib32-gamemode mangohud lutris wine-staging || true
fi

# Extra packages
pacman_retry -S --noconfirm firefox qt5-virtualkeyboard || true

# Generate fstab
print_info "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Get PARTUUID for systemd-boot
if [[ "$BOOT_MODE" == "uefi" ]]; then
    ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PART")
fi

# #########################################
# CHROOT CONFIGURATION
# #########################################
print_info "Entering chroot to configure system..."

arch-chroot /mnt /bin/bash <<CHROOT_EOF
set -e

# Logging inside chroot (plain echo since print_info doesn't exist here)
chroot_info()    { echo -e "\033[0;34m[INFO]\033[0m \$1"; }
chroot_success() { echo -e "\033[0;32m[SUCCESS]\033[0m \$1"; }
chroot_warning() { echo -e "\033[1;33m[WARNING]\033[0m \$1"; }
chroot_error()   { echo -e "\033[0;31m[ERROR]\033[0m \$1"; }

# Timezone
chroot_info "Select your timezone:"
ln -sf /usr/share/zoneinfo/\$(tzselect) /etc/localtime
hwclock --systohc
chroot_success "Timezone configured"

# Locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf
chroot_success "Locale configured"

# Hostname
echo "${HOSTNAME}" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
chroot_success "Hostname set to ${HOSTNAME}"

# Swap file
chroot_info "Creating ${SWAP_SIZE}GB swap file..."
dd if=/dev/zero of=/swapfile bs=1M count=${SWAP_MB} status=progress
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab
chroot_success "Swap file created"

# Bootloader
if [[ "${BOOT_MODE}" == "uefi" ]]; then
    chroot_info "Installing systemd-boot..."
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

    if [[ "${GPU_TYPE}" == "nvidia" ]]; then
        sed -i 's/rw$/rw nvidia-drm.modeset=1/' /boot/loader/entries/arch.conf
    fi

    chroot_success "systemd-boot installed"
else
    chroot_info "Installing GRUB..."
    grub-install --target=i386-pc "${DRIVE_PATH}"
    grub-mkconfig -o /boot/grub/grub.cfg
    chroot_success "GRUB installed"
fi

# Initramfs
chroot_info "Generating initramfs..."
mkinitcpio -P
chroot_success "Initramfs generated"

# Enable services
chroot_info "Enabling services..."
systemctl enable NetworkManager
systemctl enable udisks2

if [ -n "${DE_SERVICE}" ]; then
    systemctl enable ${DE_SERVICE}
    chroot_success "Display manager ${DE_SERVICE} enabled"
fi

# User setup
chroot_info "Creating user ${USERNAME}..."
useradd -m -G wheel,storage,power,audio,video,input,optical -s /bin/bash "${USERNAME}"

echo "Set password for ${USERNAME}:"
passwd "${USERNAME}"

echo "Set root password:"
passwd

# Sudo
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
chroot_success "sudo configured for wheel group"

# Multilib (if not already enabled for gaming)
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
fi
pacman -Sy --noconfirm

# AUR helper
if [ "${AUR_HELPER}" != "none" ]; then
    chroot_info "Installing ${AUR_HELPER}..."

    # Install as user since makepkg won't run as root
    sudo -u "${USERNAME}" bash <<AUR_EOF
    cd /tmp
    git clone https://aur.archlinux.org/${AUR_HELPER}.git
    cd ${AUR_HELPER}
    makepkg -si --noconfirm
AUR_EOF

    chroot_success "${AUR_HELPER} installed"
fi

# Gaming config
if [ "${INSTALL_GAMING}" = "true" ]; then
    chroot_info "Applying gaming optimizations..."

    cat > /etc/security/limits.d/gaming.conf <<EOF
${USERNAME}    soft    nofile  524288
${USERNAME}    hard    nofile  524288
EOF

    # Add user to gamemode group if it exists
    if getent group gamemode &>/dev/null; then
        usermod -aG gamemode "${USERNAME}"
    fi

    chroot_success "Gaming optimizations applied"
fi

# NVIDIA modeset
if [[ "${GPU_TYPE}" == "nvidia" ]]; then
    echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia.conf
    chroot_success "NVIDIA DRM modeset configured"
fi

# NTFS auto-mount
chroot_info "Detecting NTFS partitions..."
NTFS_PARTS=\$(blkid -t TYPE=ntfs -o device 2>/dev/null || true)

if [ -n "\$NTFS_PARTS" ]; then
    chroot_info "Found NTFS partitions — adding to fstab..."
    for NTFS_PART in \$NTFS_PARTS; do
        if [[ "\$NTFS_PART" == "${ROOT_PART}" ]] || [[ "\$NTFS_PART" == "${BOOT_PART}" ]]; then
            continue
        fi

        PART_UUID=\$(blkid -s UUID -o value "\$NTFS_PART")
        PART_LABEL=\$(blkid -s LABEL -o value "\$NTFS_PART" 2>/dev/null || true)

        if [ -z "\$PART_LABEL" ]; then
            MOUNT_NAME="ntfs_\${PART_UUID:0:8}"
        else
            MOUNT_NAME=\$(echo "\$PART_LABEL" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
        fi

        MOUNT_POINT="/mnt/\$MOUNT_NAME"
        mkdir -p "\$MOUNT_POINT"
        chown ${USERNAME}:${USERNAME} "\$MOUNT_POINT"

        echo "# NTFS: \$NTFS_PART" >> /etc/fstab
        echo "UUID=\$PART_UUID \$MOUNT_POINT ntfs-3g defaults,uid=1000,gid=1000,dmask=022,fmask=133,windows_names 0 0" >> /etc/fstab

        chroot_info "Mounted \$NTFS_PART at \$MOUNT_POINT"
    done
    chroot_success "NTFS partitions configured"
else
    chroot_info "No NTFS partitions found"
fi

chroot_success "System configuration complete"
CHROOT_EOF

# #########################################
# DONE
# #########################################
print_success "=========================================="
print_success "     Installation complete!"
print_success "=========================================="
echo ""
print_info "Installed:"
print_info "  Boot:    ${BOOT_MODE} / $([ "$BOOT_MODE" == "uefi" ] && echo systemd-boot || echo GRUB)"
print_info "  GPU:     ${GPU_TYPE}"
print_info "  DE:      ${DE}"
print_info "  AUR:     ${AUR_HELPER}"
print_info "  Gaming:  ${INSTALL_GAMING}"
print_info "  Swap:    ${SWAP_SIZE}GB"
echo ""
print_info "Type 'reboot' and remove the installation media."
echo ""

read -rp "Press Enter to exit..."
