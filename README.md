# 🚀 BlissIO Arch Install Script

An interactive Bash script that walks you through disk partitioning, bootloader setup, locale selection, desktop environments, and more.

![jackhammer](https://github.com/user-attachments/assets/6751b65d-f123-4872-a697-eaea70c15190) WATCH OUT THIS REPO IS WIP

> ⚠️ **Disclaimer:** This script is educational, intended for personal use or customization. It's not a "one-size-fits-all" installer, but a well-documented starting point for Arch tinkerers.

---


## ⚙️ Installation Steps

1. Boot into the Arch ISO
2. Clone the repo:

   ```bash
   git clone https://github.com/blissio/Arch-install-script.git
   cd Arch-install-script
   chmod +x arch-install.sh
   ./arch-install.sh
   ```
3. Follow the prompts (keyboard layout, partitioning, locales, DE, etc.)
4. Sit back — it's not automatic, but it's helpful.

---

## 🧩 Features

* ✅ **BIOS & UEFI Detection**
  Automatically adapts partitioning and bootloader installation based on firmware type.

* 🧠 **Interactive Walkthrough**
  Keyboard layout selection, locale config, and hostname prompts included.

* 💿 **Partitioning Options**
  Choose between **automatic** (guided) or **manual** partitioning using your preferred tools.

* 🔧 **Driver Detection**
  Auto-installs NVIDIA and Broadcom drivers based on hardware scanning via `lspci`.

* 💻 **Desktop Environment Installer**
  Pick between **XFCE**, **GNOME**, **KDE**, or no DE at all — your system, your call.

* 🛡️ **Security-First Setup**
  Adds a root password, configures a sudo-enabled user, and locks down system basics.

* 🌐 **NetworkManager Config**
  Ensures networking works out of the box — whether GUI or headless.

---

## 📦 Requirements

* A running **Arch ISO environment** (Live boot)
* Internet connection
* A clean disk (or willingness to repartition)
* Familiarity with:

  * `/dev/sdX` naming
  * UEFI vs BIOS concepts
  * Arch Linux installation philosophy

---

## 🤖 Why I Built This

As a long-time Arch/Linux user and Cybersecurity/Data Science student, I wanted something flexible that *assists* but doesn’t *take over*. It’s fast enough for re-deployments and transparent enough.

---

## 📜 License

