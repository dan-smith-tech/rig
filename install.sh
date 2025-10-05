#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_section() { echo -e "\n${BLUE}=== $1 ===${NC}\n"; }

# Helper function to handle partition naming
get_partition() {
    local dev="$1"
    local part="$2"
    if [[ "$dev" =~ ^(nvme|mmcblk) ]]; then
        echo "${dev}p${part}"
    else
        echo "${dev}${part}"
    fi
}

SKIP_OPTIONAL=0
LAPTOP=0

for arg in "$@"; do
    case $arg in
        --laptop)
            LAPTOP=1
            shift
            ;;
        --skip-optional)
            SKIP_OPTIONAL=1
            shift
            ;;
    esac
done

# Default settings
ENABLE_SWAP=false
SWAP_SIZE=8
INSTALL_NVIDIA=false

if [ "$LAPTOP" -eq 1 ]; then
    ENABLE_SWAP=true
    INSTALL_NVIDIA=true
fi

print_section "Arch Linux Installation Script"
print_warning "This script will completely wipe the selected disk!"

# Disk Selection
print_section "Disk Selection"
print_status "Available disks:"
lsblk

echo
read -p "Enter the target device to wipe (e.g., sda, nvme0n1): " TARGET_DEVICE

if [ ! -b "/dev/$TARGET_DEVICE" ]; then
    print_error "Device /dev/$TARGET_DEVICE does not exist!"
    exit 1
fi

print_warning "Selected device: /dev/$TARGET_DEVICE"
lsblk "/dev/$TARGET_DEVICE"

# Wipe device
print_status "Wiping device..."
sgdisk --zap-all "/dev/$TARGET_DEVICE"
partprobe "/dev/$TARGET_DEVICE"
sleep 2

print_section "Disk Partitioning"
print_status "Creating partition table and partitions..."

(
echo g       # GPT
echo n       # boot partition
echo          # default partition number 1
echo          # default start sector
echo +1G     # size 1GB
echo n       # EFI partition
echo          # default partition number 2
echo          # default start sector
echo +1G     # size 1GB
echo n       # LVM partition (rest of disk)
echo          # default partition number 3
echo          # default start sector
echo          # default rest of disk
echo t       # change type
echo 3       # partition 3
echo 8e00    # Linux LVM
echo w       # write
) | fdisk --wipe-partitions always "/dev/$TARGET_DEVICE"

sleep 2
partprobe "/dev/$TARGET_DEVICE"

print_status "Partitions created."

# Formatting
print_section "Disk Formatting"
print_status "Formatting boot partition (FAT32)..."
mkfs.fat -F32 "/dev/$(get_partition "$TARGET_DEVICE" 1)"
print_status "Formatting EFI partition (EXT4)..."
mkfs.ext4 "/dev/$(get_partition "$TARGET_DEVICE" 2)"
print_status "Formatting LVM partition..."
pvcreate "/dev/$(get_partition "$TARGET_DEVICE" 3)"
vgcreate vg_system "/dev/$(get_partition "$TARGET_DEVICE" 3)"

if [ "$ENABLE_SWAP" = true ]; then
    print_status "Creating swap logical volume (${SWAP_SIZE}GB)..."
    lvcreate -L "${SWAP_SIZE}GB" vg_system -n lv_swap
fi

print_status "Creating root logical volume (using remaining space)..."
lvcreate -l 100%FREE vg_system -n lv_root

modprobe dm_mod
vgscan
vgchange -ay

print_status "Formatting root logical volume..."
mkfs.ext4 /dev/vg_system/lv_root

if [ "$ENABLE_SWAP" = true ]; then
    print_status "Setting up swap..."
    mkswap /dev/vg_system/lv_swap
    swapon /dev/vg_system/lv_swap
fi

print_section "Mounting Partitions"
print_status "Mounting root partition..."
mount /dev/vg_system/lv_root /mnt

print_status "Mounting boot partition..."
mkdir -p /mnt/boot
mount "/dev/$(get_partition "$TARGET_DEVICE" 2)" /mnt/boot

print_section "Installing Base System"
print_status "Installing base packages..."
pacstrap /mnt base

print_status "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

print_status "Base system installed."

print_section "System Configuration"
USERNAME="dan"

cat > /mnt/setup_chroot.sh << EOF
#!/bin/bash

echo "Set root password..."
passwd

echo "Creating user $USERNAME..."
useradd -m -g users -G tty,input,video,audio,optical,storage,wheel "$USERNAME"
echo "Set password for $USERNAME..."
passwd "$USERNAME"

echo "Installing essential packages..."
pacman -S --noconfirm base efibootmgr git grub linux linux-firmware linux-headers lvm2 neovim networkmanager sudo

if [ "$LAPTOP" -eq 0 ]; then
    echo "Configuring git username and email..."
    read -p "Enter your Git username: " GIT_USERNAME
    read -p "Enter your Git email: " GIT_EMAIL
    git config --global user.name "\$GIT_USERNAME"
    git config --global user.email "\$GIT_EMAIL"
    git config --global diff.tool kitty
    git config --global difftool.kitty.cmd 'kitten diff \$LOCAL \$REMOTE'

    echo "Installing Plasma Desktop environment..."
    pacman -S --noconfirm plasma-desktop dolphin
fi
EOF

if [ "$INSTALL_NVIDIA" = true ]; then
cat >> /mnt/setup_chroot.sh << EOF

echo "Enabling multilib repository..."
sed -i '/^#\\[multilib\\]/,/^#Include = \\/etc\\/pacman.d\\/mirrorlist/ { s/^#//; }' /etc/pacman.conf
pacman -Syu --noconfirm

echo "Installing NVIDIA drivers and 32-bit libraries..."
pacman -S --noconfirm nvidia nvidia-utils egl-wayland lib32-nvidia-utils
EOF
fi

cat >> /mnt/setup_chroot.sh << EOF

if [ "$SKIP_OPTIONAL" -eq 0 ]; then
    echo "Installing optional packages..."
    pacman -S base-devel docker docker-buildx docker-compose fd fzf git github-cli kitty nodejs npm ripgrep rustup stow ttf-dejavu ttf-jetbrains-mono-nerd ttf-liberation ttf-nerd-fonts-symbols-mono wget zoxide zsh

    echo "Installing AUR helper (yay)..."
    if command -v yay &> /dev/null; then
        echo "yay is already installed"
    else
        TEMP_DIR=\$(mktemp -d)
        cd "\$TEMP_DIR"
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd /
        rm -rf "\$TEMP_DIR"
        echo "yay installed successfully"
    fi

    echo "AUR package installation"
    if command -v yay &> /dev/null; then
        echo "Installing Brave..."
        yay -S --noconfirm brave-bin
        echo "Brave installed"
    else
        echo "yay not available - skipping AUR package installation"
    fi

    echo "Setting zsh as default shell for $USERNAME..."
    chsh -s /bin/zsh "$USERNAME"

    echo "Installing Rust toolchain..."
    rustup default stable
fi

echo "Configuring sudo..."
echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers

echo "Configuring initramfs for encryption..."
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf

mkinitcpio -p linux

echo "Configuring locale..."
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "Configuring GRUB..."
mkdir -p /boot/EFI
mount "/dev/$(get_partition "$TARGET_DEVICE" 1)" /boot/EFI
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck

mkdir -p /boot/grub/locale
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo 2>/dev/null || true

grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager

echo "Configuration complete!"
EOF

chmod +x /mnt/setup_chroot.sh

print_status "Running system configuration..."
arch-chroot /mnt /setup_chroot.sh

rm /mnt/setup_chroot.sh

print_status "Unmounting partitions..."
umount -R /mnt

print_status "Installation complete."
print_warning "Remove installation media before reboot."

for i in {3..1}; do
    echo -ne "\rRebooting in $i seconds..."
    sleep 1
done

echo -e "\nRebooting now..."
reboot
