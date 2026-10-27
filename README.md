# My Arch Linux Setup

I value simplicity and minimalism. Even as a computer scientist, I use as little software as possible. I want my operating system to be lightweight and performant, free from bloatware, telemetry and spyware, or unnecessary features. Full configurability and complete control over my system are essential to me. Therefore, I exclusively use [Arch Linux](https://archlinux.org/).

My entire installation process is automated by a set of scripts. `install.sh` performs a zero-bloat base install of Arch Linux, and `configure-pc.sh` or `configure-laptop.sh` adds the device specific software and my preferred configurations.

## Pre-installation

1. Flash the [Arch Linux ISO](https://www.archlinux.org/download/) to a USB drive.

2. Insert the USB drive into the computer and boot into it via the BIOS boot menu.

3. Enter the Arch Linux live environment.

4. If using a wireless network, connect to it over WiFi. The install script drops into `iwctl` if it cannot reach the network, or connect beforehand:

   List available devices:

   ```bash
   iwctl device list
   ```

   Scan for available networks:

   ```bash
   iwctl station <device> scan
   ```

   List available networks:

   ```bash
   iwctl station <device> get-networks
   ```

   Connect to the network:

   ```bash
   iwctl --passphrase <password> station <device> connect <network>
   ```

   Test the connection:

   ```bash
   ping archlinux.org
   ```

## Installation

5. Fetch the install script:

   ```bash
   curl -O https://raw.githubusercontent.com/dan-smith-tech/rig/main/install.sh
   ```

6. Make the script executable:

   ```bash
   chmod +x install.sh
   ```

7. Run the install script:

   ```bash
   ./install.sh
   ```

8. Follow the prompts. The system will automatically reboot when the installation is complete.

## Post-installation

9. Login and, if using a wireless network, connect to it over WiFi:

   ```bash
   nmcli device wifi connect <network> --ask
   ```

10. Clone this repo:

    ```bash
    git clone https://github.com/dan-smith-tech/rig.git
    ```

11. Run the configure script for your device:

    ```bash
    ./configure-pc.sh
    ```

    or

    ```bash
    ./configure-laptop.sh
    ```

12. Follow the prompts. Finish the manual steps listed in [configure.md](./configure.md).
