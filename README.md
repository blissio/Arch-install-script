# Arch Linux Install Script

> ⚠️ WIP — works for my setup, use it as a starting point not a guarantee.

An interactive Bash installer for Arch Linux. Handles partitioning, bootloader, GPU drivers, desktop environment, and optional gaming setup. Supports both UEFI (systemd-boot) and BIOS/Legacy (GRUB).

---

## What it does

- Detects firmware type and partitions accordingly (GPT for UEFI, MBR for BIOS)
- Auto-detects GPU and installs the right drivers (NVIDIA, AMD, or Intel)
- DE selection: KDE Plasma, GNOME, XFCE, or minimal (no DE)
- AUR helper install: choose paru, yay, or skip
- Optional gaming setup: Steam, gamemode, MangoHud, Lutris (prompted)
- Configurable swap file size (prompted)
- Sets up PipeWire audio, NetworkManager, and udisks2
- Detects existing NTFS partitions and mounts them automatically
- Enables multilib for 32-bit support
- Configures sudo, wheel group, and a non-root user
- Validates hostname, username, and swap size before proceeding
- Exits immediately if not run as root or if no internet is detected

---

## Usage

Boot into the Arch ISO, then:

```bash
git clone https://github.com/blissio/Arch-install-script.git
cd Arch-install-script
chmod +x main.sh
./main.sh
```

You'll be prompted for:
- Keyboard layout
- Hostname and username
- Target drive
- Swap file size
- Desktop environment
- AUR helper
- Gaming setup (yes/no)
- Timezone and passwords (inside chroot)

Everything else is handled automatically.

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
- AUR helper installs as the new user inside chroot — makepkg won't run as root
- Gaming setup enables multilib automatically if not already enabled
- Existing NTFS partitions are detected and added to fstab under `/mnt/`

---

*by [blissio](https://github.com/blissio) — built for my own installs, shared for anyone who wants a starting point*
