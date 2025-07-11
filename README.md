# My Arch Linux Setup

I value simplicity and minimalism. Even as a computer scientist, I use as little software as possible. I want my operating system to be lightweight and performant, free from bloatware, spyware, or unnecessary features. Full configurability and complete control over my system are essential to me. Therefore, I exclusively use [Arch Linux](https://archlinux.org/).

I have created two scripts that automate my entire installation and configuration process. Both scripts are commented to explain each step, enabling the process to be followed manually and adapted as needed.

## Pre-installation

1. Flash the [Arch Linux ISO](https://www.archlinux.org/download/) to a USB drive.

2. Insert the USB drive into the computer and boot into it via the BIOS boot menu, and enter the Arch Linux live environment.

3. If using a wireless network, connect to it over WiFi:

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

4. Fetch the `install` script:

   ```bash
   curl -O https://raw.githubusercontent.com/dan-smith-tech/rig/main/install.sh
   ```

5. Run the `install` script:

   ```bash
   bash install.sh
   ```

6. Follow the prompts. The system will automatically reboot when the installation is complete.

## Post-installation

7. Login, and fetch the `configure` script:

   ```bash
   curl -O https://raw.githubusercontent.com/dan-smith-tech/rig/main/configure.sh
   ```

8. Run the `configure` script:

   ```bash
   bash setup.sh
   ```

9. Follow the prompts. The system will automatically reboot when the configuration is complete.
