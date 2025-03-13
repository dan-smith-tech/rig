# My Arch Linux Setup

The [Arch Linux wiki](https://wiki.archlinux.org/) contains a comprehensive, up-to-date guide on how to install Arch Linux. And the [Arch Linux Installation Guide](https://wiki.archlinux.org/index.php/Installation_guide) is a good starting point. The [Arch Linux website](https://www.archlinux.org/) provides the latest news on the distro which is important to keep up with.

> **Credit**
>
> - The wallpaper stored in `~/.config/wallpaper.png` was created by [Ash Thorp](https://www.artstation.com/artwork/ba6g2n).

## Overview

- I use Arch Linux on all of my personal devices (PC and Laptop).

  - On my PC I configure two users: a 'productivity' user running DWM for development work, and an 'entertainment' user running XFCE for playing video games (a traditional floating window manager really helps run Steam/games, which is why I don't use DWM for everything).
  - On my laptop, I run only DWM.

- I like my systems to be as lightweight as possible, so run the smallest/simplest versions of the tools I need, and don't use tools that aren't necessary (such as display managers).

- I use the terminal for everything other than browsing the web and playing video games, as I am a massive advocate of FOSS and simplicity.

- I like to configure everything in dotfiles (no GUIs if they can be avoided), and use Stow to sync the settings that are not specific to a user type (i.e., window manager dotfiles are not synced, but shell, terminal, file editor, etc. are).

## Pre-installation

### Install Ventoy

[Ventoy](https://www.ventoy.net/en/index.html) is a tool to create bootable USB drives. It is a great tool to have as it allows you to boot multiple ISOs from a single USB drive and not have to format the drive each time you want to try a different distro.

### Download the ISO

[Download the Arch Linux ISO from the bottom of the page](https://www.archlinux.org/download/) and place it inside the root of the Ventoy USB drive.

### Boot into the USB

Insert the Ventoy USB drive into the computer and boot into it by selecting it from the boot menu. You may need to change the boot order in the BIOS settings, or your BIOS may have a boot menu key that you can press at startup to select the USB drive.

Once Ventoy boots, you will see a list of ISOs that you can boot from. Select the Arch Linux ISO and press enter.

> **Note**: Disable Secure Boot in your BIOS settings if you have trouble booting into the USB drive.

When the Arch Linux ISO boots, you will be presented with a GRUB2 menu. Select the first option to boot into the live environment (if you are using UEFI mode). Arch Linux will boot into the live environment and you can start the installation process when it finishes copying the image to RAM.

> **Note**: If Arch Linux does not boot into the live environment because it cannot find a device or path, then you may need to enter GRUB2 mode in Ventoy by pressing `ctrl + r` before booting into the Arch Linux ISO.

Ensure the system is working by setting the system timezone:

```bash
timedatectl set-timezone <Region>/<City>
```

## Initial network configuration

If you are using a wired connection, then you can skip this step. If you are using Wi-Fi, then you will need to connect to your network before proceeding with the installation.

Using `iwctl` (iNet Wireless Control), you can scan for networks and connect to them. First, list the available devices:

```bash
iwctl device list
```

Scan for available networks:

```bash
iwctl station <device> scan
```

List the available networks:

```bash
iwctl station <device> get-networks
```

Connect to your network:

```bash
iwctl --passphrase <password> station <device> connect <network>
```

Test the connection:

```bash
ping archlinux.org
```

If the connection is successful, you should see output from the `ping` appearing every second. Press `Ctrl + C` to stop the `ping`.

## Disk partitioning

List the available disks:

```bash
lsblk
```

Identify the disk you want to install Arch Linux on. If you are unsure, use the size of the disk to determine which is the primary disk.

> **Note**: If re-partitioning a device, run `sgdisk --zap-all /dev/sda` followed by `partprobe /dev/sda` to completely wipe it beforehand. A restart may be required for everything to sync.

Enter disk partitioning mode for the disk:

```bash
fdisk /dev/<device>
```

> **Note**: Make sure _not_ to select a partition (e.g., `/dev/sda1`) but the disk itself (e.g., `/dev/sda`).

Create an empty partition table:

```bash
g
```

> **Note**: At any point you can type `p` to print the current partition table.

### Create the boot partition

Create a new partition:

```bash
n
```

Leave the partition number as the default: press `Enter`.

Leave the first sector (beginning of the partition) as the default: press `Enter`.

Make this new partition 1 gigabyte in size:

```bash
+1G
```

If prompted to remove the signature, type `y` and press `Enter`.

### Create the EFI partition

Create a new partition:

```bash
n
```

Leave the partition number as the default: press `Enter`.

Leave the first sector (beginning of the partition) as the default: press `Enter`.

Make this new partition 1 gigabyte in size:

```bash
+1G
```

### Create the LVM partition

Create a new partition:

```bash
n
```

Leave the partition number as the default: press `Enter`.

Leave the first sector (beginning of the partition) as the default: press `Enter`.

Leave the last sector (end of the partition) as the default, to use all remaining space: press `Enter`.

Enter type selection mode:

```bash
t
```

Select the partition you just created: press `Enter`.

Select the Linux large volume manager (LVM) type:

```bash
44
```

### Write the changes to disk

> **Note**: Running the following command will erase all data on the disk. Make sure you have backed up any important data before proceeding.

Write the changes to disk:

```bash
w
```

## Disk formatting

Format the boot (first) partition as FAT32:

```bash
mkfs.fat -F32 /dev/<device>1
```

Format the EFI (second) partition as FAT32:

```bash
mkfs.ext4 /dev/<device>2
```

Encrypt the home LVM (third) partition, as it will contain the root and swap volumes (i.e., the actual stuff we store and use on our computer):

```bash
cryptsetup luksFormat /dev/<device>3
```

Type `YES` to confirm the encryption.

Enter and verify the passphrase for the encryption (i.e., the password you will use every time you log in to your computer).

Open the encrypted partition:

```bash
cryptsetup open --type luks /dev/<device>3 lvm
```

> **Note**: The `lvm` name is arbitrary and can be anything you want - it is how we will refer to the partition in the next steps.

Create the physical volume:

```bash
pvcreate /dev/mapper/lvm
```

Create the system volume group:

```bash
vgcreate vg_system /dev/mapper/lvm
```

Create the logical volume for the system:

```bash
lvcreate -L 30GB vg_system -n lv_root
```

[Optional] Create the logical volume for the swap partition:

```bash
lvcreate -L <RAM-size>GB vg_system -n lv_swap
```

[Optional] Configure the swap partition:

```bash
mkswap /dev/vg_system/lv_swap
```

[Optional] Enable the swap partition:

```bash
swapon /dev/vg_system/lv_swap
```

> **Note**: We can run `vgdisplay` to see the volume group information, and `lvdisplay` to see the logical volume information.

```bash
modprobe dm_mod
```

Scan for the LVM volumes:

```bash
vgscan
```

Activate the volume group:

```bash
vgchange -ay
```

Format the LVM partition as ext4:

```bash
mkfs.ext4 /dev/vg_system/lv_system
```

## Partition mounting

Mount the root partition:

```bash
mount /dev/vg_system/lv_system /mnt
```

Create the boot directory:

```bash
mkdir /mnt/boot
```

Mount the EFI (second) partition:

```bash
mount /dev/<device>2 /mnt/boot
```

> **Note**: We are not mounting the boot (first) partition...

## Configure base system

```bash
pacstrap -i /mnt base
```

**Note**: If any packages ask which version to install, select the default version by pressing `Enter`.

Generate the `fstab` file (the file that automatically mounts volumes/partitions on boot):

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

> This will append the UUIDs of the partitions to the `fstab` file: root, boot, home, and swap.

Chroot into the new system:

```bash
arch-chroot /mnt
```

Set root password:

```bash
passwd
```

Enter and confirm the root password.

Create productivity user:

```bash
useradd -m -G tty,input,video,audio,optical,storage,wheel p
```

Set productivity user password:

```bash
passwd p
```

Enter and confirm the password.

Create entertainment user:

```bash
useradd -m -G tty,input,video,audio,optical,storage,wheel e
```

Set entertainment user password:

```bash
passwd e
```

Enter and confirm the password.

Install system packages:

```bash
pacman -S alsa-tools alsa-utils base base-devel clang docker docker-compose efibootmgr element-desktop fd feh fzf git github-cli grub kitty linux linux-firmware linux-headers lvm2 neovim networkmanager nodejs npm nvidia nvidia-utils pipewire pipewire-alsa pipewire-audio pipewire-pulse ripgrep stow sudo sysstat ttf-dejavu ttf-jetbrains-mono-nerd ttf-liberation ttf-nerd-fonts-symbols-mono unzip wget xclip xdg-utils xfwm4 xorg xorg-server xorg-xinit zoxide zsh
```

> **Note**: If any packages ask which version to install, select the default version by pressing `Enter`.

> **Note**: If using Intel or AMD graphics, instead of installing the Nvidia packages, install `mesa intel-media-driver` instead.

Uncomment the `multilib` section in `/etc/pacman.conf` to enable 32-bit packages to be installed:

```bash
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Upgrade the system:

```bash
pacman -Syu
```

Install 32-bit packages:

```bash
pacman -S lib32-nvidia-utils steam
```

Grant the user sudo privileges:

```bash
sudo EDITOR=nvim visudo
```

Uncomment the line (or the `NOPASSWD` variant where applicable):

```bash
%wheel ALL=(ALL:ALL) ALL
```

Make sure the kernel knows how to deal with encrypted partitions:

```bash
nvim /etc/mkinitcpio.conf
```

Add `encrypt` to the `HOOKS` array:

```bash
HOOKS=(... block encrypt lvm2 filesystems ...)
```

Generate the ramdisk:

```bash
mkinitcpio -p linux
```

Set locale:

```bash
nvim /etc/locale.gen
```

Uncomment the locale(s) you want to use:

```bash
en_GB.UTF-8 UTF-8
```

...and...

```bash
en_US.UTF-8 UTF-8
```

Generate the locale:

```bash
locale-gen
```

Add the encrypt device to the GRUB configuration:

```bash
nvim /etc/default/grub
```

Add `cryptdevice=/dev/<device>3:vg_system` to the `GRUB_CMDLINE_LINUX_DEFAULT` line:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet cryptdevice=/dev/<device>3:vg_system"
```

Setup EFI partition:

```bash
mkdir /boot/EFI
```

Mount the EFI partition:

```bash
mount /dev/<device>1 /boot/EFI
```

Install bootloader:

```bash
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
```

Generate the GRUB configuration:

```bash
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
```

Generate config file:

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

Enable network manager:

```bash
systemctl enable NetworkManager
```

### Reboot

Exit the chroot environment:

```bash
exit
```

Unmount the partitions:

```bash
umount -a
```

Reboot the system:

```bash
reboot
```

> **Note**: You can now unplug the USB.

### Post-installation

Name the device:

```bash
sudo hostnamectl hostname <name>
```

Connect to the network (if using wireless):

```bash
nmcli device wifi connect <SSID> password <password>
```

Install the AUR:

```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

Install Brave (browser):

```bash
yay -Sy brave-bin
```

## Global user configuration

Enable auto-login by adding the following to the top of `/etc/pam.d/login`:

```bash
auth sufficient pam_permit.so
```

**Perform the following for each user individually...**

List installed shells:

```bash
chsh -l
```

Set ZHS as the default shell:

```bash
chsh -s /usr/bin/zsh
```

> **Note:** The configuration for ZHS can be found in the `~/.zshrc` and `~/.zprofile` files (stored in the `stow` subdirectory of this repo).

Clone this repo into the root directory:

```bash
git clone https://github.com/dan-smith-tech/rig.git
```

For each of the users, run the `stow` command to symlink the configuration files:

```bash
stow --adopt -t ~ -d rig/stow .
```

> Note: The `--adopt` flag overrides the dotfiles stored in this repo with the ones already configured on the system. This can be used to override all files dotfiles on the system easily without having to delete them first, and then after the symlinks are created, `git restore .` can be applied to this repo to revert all configs to how they are here.

### Git

Configure Kitty to be the diff tool:

```bash
git config --global diff.tool kitty
git config --global difftool.kitty.cmd 'kitten diff $LOCAL $REMOTE'
```

## Productivity (p) user configuration

Clone the DWM repository:

```bash
sudo git clone https://git.suckless.org/dwm
```

Navigate to the cloned DWM directory:

```bash
cd dwm
```

Copy the configruation from the `p/dwm` subdirectory of this repo:

```bash
sudo cp ~/rig/p/dwm/config.def.h config.def.h
```

```bash
sudo cp ~/rig/p/dwm/dwm.c dwm.c
```

Build and install DWM:

```bash
sudo make clean install
```

> **Note:** If rebuilding DWM after making edits to any of the config, make sure to remove the generated `config.h` beforehand.

Clone the DWM blocks repository:

```bash
sudo git clone https://github.com/torrinfail/dwmblocks.git
```

Navigate into the cloned DWM blocks directory:

```bash
cd dwmblocks
```

Copy the DWM blocks configuration from the `p/dwm` subdirectory of this repo:

```bash
sudo cp ~/rig/p/dwm/blocks.def.h blocks.def.h
```

Build and install DWM blocks:

```bash
sudo make clean install
```

> **Note:** If rebuilding DWM blocks after making edits to any of the config, make sure to remove the generated `config.h` beforehand.

Copy the Xorg startup configuration from the `p` subdirectory of this repo:

```bash
sudo cp ~/rig/p/.xinitrc ~/.xinitrc
```

## Entertainment (e) user configuration

Add the configuration for the XFCE window manager:

```
cp -rf rig/e/.config/xfce4 .config/.
```

Download Fluent XFCE theme:

```bash
git clone https://github.com/vinceliuice/Fluent-gtk-theme.git
```

Install Fluent XFCE theme:

```bash
Fluent-gtk-theme/install.sh -n Fluent -c dark -s standard -i arch --tweaks solid round noborder
```

> Note: XFCE themes are stored in `~/.local/share/themes`.

Give permissions to the `/g` mountpoint where games are stored:

```bash
sudo chown -R e /g
```

#### Setup controller dongle with `xone`

Clone the repo:

```bash
git clone https://github.com/medusalix/xone
```

> Note: At the time of writing this documentation [this](https://github.com/tskaar/xone/tree/fix-6.12) fork and branch are required to fix compatibility issue with new kernel.

Install `xone`:

```bash
cd xone && sudo ./install.sh --release
```

Download dongle firmware:

```bash
sudo xone-get-firmware.sh
```

## Miscellaneous configuration

## If `pacman` mirrors start to `404`

Delete the mirror sync:

```bash
sudo rm -rf /var/lib/pacman/sync/*
```

Refresh the package databses:

```bash
sudo pacman -Syy
```

### Laptop-specific configuration

In order to auto-login as a specific user, open the `getty tty1` service config file:

```bash
sudo systemctl edit getty@tty1
```

Between the comments that don't get overriden (towards the top of the file)m add:

```bash
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin your_username --noclear %I $TERM
```

Enabled the modified service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable getty@tty1
```
