# My Arch Linux Setup

I value simplicity and minimalism. Even as a computer scientist, I use as little software as possible. I want my operating system to be lightweight and performant, free from bloatware, spyware, or unnecessary features. Full configurability and complete control over my system are essential to me. For these reasons, I exclusively use [Arch Linux](https://archlinux.org/).

## Pre-installation

1. Flash the [Arch Linux ISO](https://www.archlinux.org/download/) to a USB drive.

2. Insert the USB drive into the computer and boot into it via the BIOS boot menu, and enter the live environment.

3. If using a wireless network connect, connect to the network over WiFi:

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

## Automated installation

I have made two scripts that automate my entire installation and setup process:

1. Fetch install script:

   ```bash
   curl -O https://raw.githubusercontent.com/dan-smith-tech/rig/main/install.sh
   ```

2. Run the install script, and follow the prompts:

   ```bash
   bash install.sh
   ```

3. Once the system has rebooted, login, and fetch the post-install setup script:

   ```bash
   curl -O https://raw.githubusercontent.com/dan-smith-tech/rig/main/setup.sh
   ```

4. Run the setup script, and follow the prompts:

   ```bash
   bash setup.sh
   ```

## Manual installation

The following are the steps taken by the automated installation script, which can be followed manually if desired.

### Disk partitioning

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

Format the EFI (second) partition as EXT4:

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

> **[Optional]**
>
> Create the logical volume for the swap partition:
>
> ```bash
> lvcreate -L <RAM-size>GB vg_system -n lv_swap
> ```
>
> Configure the swap partition:
>
> ```bash
> mkswap /dev/vg_system/lv_swap
> ```
>
> Enable the swap partition:
>
> ```bash
> swapon /dev/vg_system/lv_swap
> ```

Create the logical volume for the home directory:

```bash
lvcreate -l 100%FREE vg_system -n lv_home
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
mkfs.ext4 /dev/vg_system/lv_root
```

Format the home partition as ext4:

```bash
mkfs.ext4 /dev/vg_system/lv_home
```

## Partition mounting

Mount the root partition:

```bash
mount /dev/vg_system/lv_root /mnt
```

Create the boot directory:

```bash
mkdir /mnt/boot
```

Mount the EFI (second) partition:

```bash
mount /dev/<device>2 /mnt/boot
```

> **Note**: We are NOT mounting the boot (first) partition...

Create the home directory:

```bash
mkdir /mnt/home
```

Mount the home partition:

```bash
mount /dev/vg_system/lv_home /mnt/home
```

## Configure base system

```bash
pacstrap -i /mnt base
```

**Note**: If any packages ask which version to install, select the default version by pressing `Enter`.

Generate the `fstab` file (the file that automatically mounts volumes/partitions on boot):

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

> This will append the UUIDs of the partitions to the `fstab` file: root, boot, and home (and optionally swap).

Chroot into the new system:

```bash
arch-chroot /mnt
```

Set root password:

```bash
passwd
```

Enter and confirm the root password.

Create user:

```bash
useradd -m -g users -G tty,input,video,audio,optical,storage,wheel dan
```

Set productivity user password:

```bash
passwd dan
```

Enter and confirm the password.

Install system packages:

```bash
pacman -S efibootmgr git grub linux linux-firmware linux-headers lvm2 neovim networkmanager sudo xorg xorg-server xorg-xinit
```

```bash
pacman -S alsa-tools alsa-utils base base-devel clang docker docker-compose efibootmgr fd feh fzf git github-cli grub kitty linux linux-firmware linux-headers lvm2 neovim networkmanager nodejs npm nvidia nvidia-utils pipewire pipewire-alsa pipewire-audio pipewire-pulse ripgrep stow sudo sysstat ttf-dejavu ttf-jetbrains-mono-nerd ttf-liberation ttf-nerd-fonts-symbols-mono unzip wget xclip xdg-utils xfwm4 xorg xorg-server xorg-xinit zoxide zsh
```

> **Note**: If any packages ask which version to install, select the default version by pressing `Enter`.

> **Note**: If using Intel or AMD graphics, instead of installing the NVIDIA packages, install `mesa intel-media-driver` instead.

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

Connect to the network (if using wireless):

```bash
nmcli device wifi connect <SSID> password <password>
```

Clone this repo into the root directory:

```bash
git clone https://github.com/dan-smith-tech/rig.git
```

Set ZHS as the default shell:

```bash
chsh -s /usr/bin/zsh
```

> **Note:** The configuration for ZHS can be found in the `~/.zshrc` and `~/.zprofile` files (stored in the `stow` subdirectory of this repo).

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

Install Xone:

```bash
yay -Sy xone-dkms
```

In order to auto-login as a specific user, open the `getty tty1` service config file:

```bash
sudo systemctl edit getty@tty1
```

Between the comments that don't get overriden (towards the top of the file)m add:

```bash
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin dan --noclear %I $TERM
```

Enabled the modified service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable getty@tty1
```

Run `stow` to symlink the configuration files:

```bash
stow --adopt -t ~ -d rig/dotfiles .
```

> Note: The `--adopt` flag overrides the dotfiles stored in this repo with the ones already configured on the system. This can be used to override all files dotfiles on the system easily without having to delete them first, and then after the symlinks are created, `git restore .` can be applied to this repo to revert all configs to how they are here.

Clone the DWM repository:

```bash
sudo git clone https://git.suckless.org/dwm
```

Navigate to the cloned DWM directory:

```bash
cd dwm
```

Copy the configuration from the `p/dwm` subdirectory of this repo:

```bash
sudo cp ~/rig/build/config.def.h config.def.h
```

Build and install DWM:

```bash
sudo make clean install
```

> **Note:** If rebuilding DWM after making edits to any of the config, make sure to remove the generated `config.h` beforehand.

## Miscellaneous configuration

## If `pacman` mirrors start to `404`

Delete the mirror sync:

```bash
sudo rm -rf /var/lib/pacman/sync/*
```

Refresh the package databases:

```bash
sudo pacman -Syy
```

## Per-device UI scaling

Add the following to `~/.Xdefaults` in order to scale the UI:

```bash
Xft.dpi: 192
```

Make the window managers boot Kitty with a specific font-size:

```bash
"kitty -o font_size=38"
```

## Laptop scrolling

Add the following to a startup script to enable natural scrolling for the touchpad:

```bash
xinput set-prop 'SYNA8004:00 06CB:CD8B Touchpad' 'libinput Natural Scrolling Enabled' 1 &
```
