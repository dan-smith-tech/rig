# My Arch Linux Setup

I value simplicity and minimalism. Even as a computer scientist, I use as little software as possible. I want my operating system to be lightweight, performant, and free from telemetry and spyware. Full configurability and complete control over my system are essential to me. Therefore, I exclusively use [Arch Linux](https://archlinux.org/).

## Pre-installation

1. Flash the [Arch Linux ISO](https://www.archlinux.org/download/) to a USB drive.

2. Insert the USB drive into the computer and temporarily boot into it via the BIOS boot menu.

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

7. Run the install:

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

11. Run the configure script for the relevant device:

    ```bash
    just <device>
    ```

## Manual Configuration

### Plasma

1. Open **System Settings** and configure:

   1. Global Theme colours, Icons, Login Screen
   2. Wallpaper
   3. Screen Locking
   4. Power Management
   5. Users
   6. Session

2. Right click on the panel and select **Panel Configuration** to setup and bin applets to the bar.

3. Press `Meta + T` to configure the window layout settings.

### Brave

1. Install Proton Pass extension.

1. Sync settings at brave://settings/braveSync/setup.

1. Open brave://settings and configure:

   1. Get started:
      1. On startup
      1. Customise new tab page
   1. Appearance
   1. Content:
      1. Containers
   1. Shields
      1. Forget me
      1. Content filtering
      1. Social media blocking
   1. Privacy and security
      1. Data collection
   1. Leo
   1. Autofill and passwords
   1. Downloads
   1. System:
      1. Show full-screen reminder to press Esc on exit

1. Enable and disable icons in the toolbar.

### GitHub

1. Copy public key:

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

1. Go to [GitHub Settings → SSH and GPG keys](https://github.com/settings/keys)
1. Select `New SSH key`, paste the content, and save.

### Steam

1. Add the following Gamescope settings to launch settings:

   ```bash
   gamescope -W 3440 -H 1440 -w 3440 -h 1440 -r 144 --hdr-enabled --hdr-debug-force-output --fullscreen --force-grab-cursor -- env DXVK_HDR=1 ENABLE_HDR_WSI=1 %command% --launcher-skip
   ```
