#!/bin/bash

set -e

USERNAME="dan"
SKIP_OPTIONAL=0
ENABLE_SWAP=false
SWAP_SIZE=8
INSTALL_NVIDIA=true

echo "=== Arch Linux Installation Script ==="
echo "This script will completely wipe the selected disk!"

echo
read -p "Enable swap? (y/N): " enable_swap
case "$enable_swap" in
    [yY]|[yY][eE][sS]) ENABLE_SWAP=true ;;
    *) ENABLE_SWAP=false ;;
esac

if [ "$ENABLE_SWAP" = true ]; then
    read -p "Enter swap size in GB (default 8): " swap_size_input
    if [ -n "$swap_size_input" ] && [[ "$swap_size_input" =~ ^[0-9]+$ ]]; then
        SWAP_SIZE="$swap_size_input"
    fi
fi

read -p "Install NVIDIA drivers? (Y/n): " install_nvidia
case "$install_nvidia" in
    [nN]|[nN][oO]) INSTALL_NVIDIA=false ;;
    *) INSTALL_NVIDIA=true ;;
esac

get_partition() {
    local dev="$1"
    local part="$2"
    if [[ "$dev" =~ ^(nvme|mmcblk) ]]; then
        echo "${dev}p${part}"
    else
        echo "${dev}${part}"
    fi
}

echo
echo "Available disks:"
lsblk
echo
read -p "Enter the target device to wipe (e.g., sda, nvme0n1): " TARGET_DEVICE
if [ ! -b "/dev/$TARGET_DEVICE" ]; then
    echo "Error: Device /dev/$TARGET_DEVICE does not exist!"
    exit 1
fi
echo "Selected device: /dev/$TARGET_DEVICE"
lsblk "/dev/$TARGET_DEVICE"
echo "Wiping device..."
sgdisk --zap-all "/dev/$TARGET_DEVICE"
partprobe "/dev/$TARGET_DEVICE"
sleep 2

echo "Creating partitions..."
parted -s /dev/$TARGET_DEVICE \
    mklabel gpt \
    mkpart primary fat32 1MiB 1GiB \
    mkpart primary ext4 1GiB 2GiB \
    mkpart primary ext4 2GiB 100% \
    set 3 lvm on
sleep 2
partprobe "/dev/$TARGET_DEVICE"

echo "Formatting partitions..."
mkfs.fat -F32 "/dev/$(get_partition "$TARGET_DEVICE" 1)"
mkfs.ext4 "/dev/$(get_partition "$TARGET_DEVICE" 2)"
pvcreate "/dev/$(get_partition "$TARGET_DEVICE" 3)"
vgcreate vg_system "/dev/$(get_partition "$TARGET_DEVICE" 3)"
if [ "$ENABLE_SWAP" = true ]; then
    lvcreate -L "${SWAP_SIZE}GB" vg_system -n lv_swap
fi
lvcreate -l 100%FREE vg_system -n lv_root
modprobe dm_mod
vgscan
vgchange -ay
mkfs.ext4 /dev/vg_system/lv_root
if [ "$ENABLE_SWAP" = true ]; then
    mkswap /dev/vg_system/lv_swap
    swapon /dev/vg_system/lv_swap
fi

echo "Mounting partitions..."
mount /dev/vg_system/lv_root /mnt
mkdir -p /mnt/boot
mount "/dev/$(get_partition "$TARGET_DEVICE" 2)" /mnt/boot

echo "Installing base system..."
pacstrap /mnt base
genfstab -U /mnt >> /mnt/etc/fstab

echo "About to run chroot setup (set password for root and then the user)..."
cat > /mnt/setup_chroot.sh << EOF
#!/bin/bash

passwd

useradd -m -g users -G tty,input,video,audio,optical,storage,wheel "$USERNAME"
passwd "$USERNAME"

pacman -S --noconfirm base efibootmgr git grub linux linux-firmware linux-headers lvm2 neovim networkmanager sudo
pacman -S --noconfirm plasma dolphin

if [ "$INSTALL_NVIDIA" = true ]; then
    sed -i '/^#\\[multilib\\]/,/^#Include = \\/etc\\/pacman.d\\/mirrorlist/ { s/^#//; }' /etc/pacman.conf
    pacman -Syu --noconfirm
    pacman -S --noconfirm nvidia nvidia-utils nvidia-container-toolkit egl-wayland lib32-nvidia-utils steam
fi

if [ "$SKIP_OPTIONAL" -eq 0 ]; then
    pacman -S --noconfirm base-devel git docker docker-buildx docker-compose fd fzf github-cli kitty nodejs npm openssh ripgrep rustup stow sysstat tree-sitter-cli ttf-dejavu ttf-jetbrains-mono-nerd ttf-liberation ttf-nerd-fonts-symbols-mono unzip wget wl-clipboard zoxide zsh

    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    yay -S --noconfirm brave-bin

    curl -f https://zed.dev/install.sh | sh

    sudo -u "$USERNAME" -H bash -c '
        ssh-keygen -t rsa -b 4096 -f "/home/'"$USERNAME"'/.ssh/id_rsa" -N "" -q

        git config --global diff.tool kitty
        git config --global difftool.kitty.cmd '\\''kitten diff $LOCAL $REMOTE'\\''    

        cd /home/'"$USERNAME"'
        git clone https://github.com/dan-smith-tech/rig rig
        cd rig/dotfiles
        stow --adopt -t /home/"$USERNAME" zshrc nvim kitty
        git restore .

        chsh -s /bin/zsh

        rustup default stable
    '
fi

echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers

sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -p linux

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

mkdir -p /boot/EFI
mount "/dev/$(get_partition "$TARGET_DEVICE" 1)" /boot/EFI
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck

mkdir -p /boot/grub/locale
cp /usr/share/locale/en\\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo 2>/dev/null || true
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable sddm.service
systemctl enable NetworkManager

echo "Setup complete."
EOF

chmod +x /mnt/setup_chroot.sh
arch-chroot /mnt /setup_chroot.sh
rm /mnt/setup_chroot.sh

echo "Unmounting partitions..."
umount -R /mnt

echo "Installation complete."
echo "Remove installation media and reboot."

for i in {3..1}; do
    echo -ne "Rebooting in $i seconds...\r"
    sleep 1
done
echo
reboot
