# BlissIO's Arch Install Script

## Disclaimer

This script is provided as-is, without any warranty or guarantee. Use it at your own risk. It is recommended to review and understand the script before running it on your system.

## Features
This script automates the installation process of Arch Linux using a simple command-line interface. It provides the following features:

1. Checks if the system uses UEFI or BIOS for boot.
2. Updates the repositories and keyrings.
3. Allows the user to choose a keyboard layout from the available options.
4. Guides the user through automatic or manual partitioning of the selected drive.
5. Generates the fstab file.
6. Sets up locales and timezone.
7. Prompts the user for hostname, root password, and a new user.
8. Installs the GRUB bootloader for BIOS or the EFISTUB for UEFI systems.
9. Configures sudo access for the new user.
10. Optionally installs and configures a desktop environment (XFCE, GNOME, KDE) or NetworkManager.

## Usage

1. Download the script file.
2. Make it executable: `chmod +x arch_install.sh`
3. Run the script with root privileges: `sudo ./arch_install.sh`
4. Follow the on-screen prompts and provide the necessary inputs.

## Requirements

- An internet connection is required during the installation process.
- Make sure the script is run on a machine compatible with Arch Linux.

