# Arch Linux Install Script

> ⚠️ WIP — works for my setup, use it as a starting point not a guarantee.

An interactive Bash installer for Arch Linux. Handles partitioning, bootloader, GPU drivers, and a full KDE Plasma gaming setup. Supports both UEFI (systemd-boot) and BIOS/Legacy (GRUB).

---

## What it does

- Detects firmware type and partitions accordingly (GPT for UEFI, MBR for BIOS)
- Auto-detects GPU and installs the right drivers (NVIDIA, AMD, or Intel)
- Installs KDE Plasma with SDDM
- Sets up PipeWire audio, NetworkManager, and udisks2
- Creates an 8GB swap file instead of a swap partition
- Detects existing NTFS partitions and mounts them automatically
- Enables multilib for 32-bit support
- Applies gamemode limits and NVIDIA DRM modeset if needed
- Configures sudo, wheel group, and a non-root user

---

## Usage

Boot into the Arch ISO, then:

```bash
git clone https://github.com/blissio/Arch-install-script.git
cd Arch-install-script
chmod +x main.sh
./main.sh
```

You'll be prompted for keyboard layout, target drive, hostname, username, and timezone. Everything else is handled automatically.

---

## Requirements

- Arch Linux live ISO (booted)
- Internet connection
- A drive you're okay wiping
- Basic familiarity with `/dev/sdX` naming and UEFI vs BIOS

---

## Notes

- **UEFI** systems use systemd-boot with a 1GB EFI partition
- **BIOS** systems use GRUB with a 512MB boot partition
- NVIDIA systems get `nvidia-drm.modeset=1` set automatically
- Existing NTFS partitions are detected and added to fstab under `/mnt/`
- KDE is the only DE option right now — GNOME/XFCE support coming later

---

*by [blissio](https://github.com/blissio) — built for my own installs, shared for anyone who wants a starting point*
