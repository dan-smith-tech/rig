#!/bin/bash

# Arch Linux Installation Script
# Run this directly from the Arch Linux ISO

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to prompt for user input
prompt_user() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        eval "$var_name=\"\${input:-$default}\""
    else
        read -p "$prompt: " input
        eval "$var_name=\"$input\""
    fi
}

# Function to prompt for yes/no
prompt_yn() {
    local prompt="$1"
    local default="$2"
    local response
    
    while true; do
        if [ "$default" = "y" ]; then
            read -p "$prompt [Y/n]: " response
            response=${response:-y}
        elif [ "$default" = "n" ]; then
            read -p "$prompt [y/N]: " response
            response=${response:-n}
        else
            read -p "$prompt [y/n]: " response
        fi
        
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Function to get correct partition name (handles nvme and mmcblk devices)
get_partition() {
    local dev="$1"
    local part="$2"
    if [[ "$dev" =~ ^(nvme|mmcblk) ]]; then
        echo "${dev}p${part}"
    else
        echo "${dev}${part}"
    fi
}

print_section "Arch Linux Installation Script"
print_warning "This script will completely wipe the selected disk!"

# ===========================================
# DISK SELECTION AND PARTITIONING
# ===========================================

print_section "Disk Selection"
print_status "Available disks:"
lsblk

echo
prompt_user "Enter the target device (e.g., sda, nvme0n1)" "TARGET_DEVICE"

# Validate device exists
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

# Create partition table and partitions using fdisk
print_status "Creating GPT partition table..."
(
echo g      # Create GPT partition table
echo n      # New partition (boot)
echo        # Default partition number
echo        # Default first sector
echo +1G    # Size: 1GB
echo n      # New partition (EFI)
echo        # Default partition number
echo        # Default first sector
echo +1G    # Size: 1GB
echo n      # New partition (LVM)
echo        # Default partition number
echo        # Default first sector
echo        # Default last sector (use remaining space)
echo t      # Change partition type
echo 3      # Select partition 3
echo 44     # LVM type
echo w      # Write changes
) | fdisk --wipe-partitions always "/dev/$TARGET_DEVICE"

# Wait for partitions to be recognized
sleep 2
partprobe "/dev/$TARGET_DEVICE"

print_status "Partitions created successfully!"

# ===========================================
# DISK FORMATTING
# ===========================================

print_section "Disk Formatting"

# Format boot partition (FAT32)
print_status "Formatting boot partition as FAT32..."
mkfs.fat -F32 "/dev/$(get_partition "$TARGET_DEVICE" 1)"

# Format EFI partition (EXT4)
print_status "Formatting EFI partition as EXT4..."
mkfs.ext4 "/dev/$(get_partition "$TARGET_DEVICE" 2)"

# Encrypt LVM partition
print_status "Setting up LUKS encryption on LVM partition..."
print_warning "You will need to enter a passphrase for disk encryption."
print_warning "This passphrase will be required every time you boot your system."
cryptsetup luksFormat "/dev/$(get_partition "$TARGET_DEVICE" 3)"

print_status "Opening encrypted partition..."
cryptsetup open --type luks "/dev/$(get_partition "$TARGET_DEVICE" 3)" lvm

# ===========================================
# LVM SETUP
# ===========================================

print_section "LVM Setup"

# Create physical volume
print_status "Creating physical volume..."
pvcreate /dev/mapper/lvm

# Create volume group
print_status "Creating volume group..."
vgcreate vg_system /dev/mapper/lvm

# Create root logical volume (use all space)
print_status "Creating root logical volume (use all space)..."
lvcreate -l 100%FREE vg_system -n lv_root

# Ask about swap
ENABLE_SWAP=false
if prompt_yn "Do you want to create a swap partition?" "n"; then
    ENABLE_SWAP=true
    prompt_user "Enter swap size in GB (recommend same as RAM)" "SWAP_SIZE" "8"
    print_status "Creating swap logical volume (${SWAP_SIZE}GB)..."
    lvcreate -L "${SWAP_SIZE}GB" vg_system -n lv_swap
fi

# Load device mapper module and scan for LVM volumes
print_status "Loading device mapper and scanning for LVM volumes..."
modprobe dm_mod
vgscan
vgchange -ay

# Format logical volumes
print_status "Formatting logical volumes..."
mkfs.ext4 /dev/vg_system/lv_root

# Setup swap if enabled
if [ "$ENABLE_SWAP" = true ]; then
    print_status "Setting up swap..."
    mkswap /dev/vg_system/lv_swap
    swapon /dev/vg_system/lv_swap
fi

# ===========================================
# PARTITION MOUNTING
# ===========================================

print_section "Mounting Partitions"

# Mount root partition
print_status "Mounting root partition..."
mount /dev/vg_system/lv_root /mnt

# Create and mount boot directory
print_status "Creating and mounting boot directory..."
mkdir /mnt/boot
mount "/dev/$(get_partition "$TARGET_DEVICE" 2)" /mnt/boot

# ===========================================
# BASE SYSTEM INSTALLATION
# ===========================================

print_section "Installing Base System"

# Install base system
print_status "Installing base system packages..."
pacstrap /mnt base

# Generate fstab
print_status "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

print_status "Base system installed successfully!"

# ===========================================
# SYSTEM CONFIGURATION
# ===========================================

print_section "System Configuration"

USERNAME="dan"

# Create chroot configuration script
cat > /mnt/setup_chroot.sh << EOF
#!/bin/bash

# Helper for partition naming (copied logic)
get_partition() {
    local dev="$TARGET_DEVICE"
    local part="\$1"
    if [[ "\$dev" =~ ^(nvme|mmcblk) ]]; then
        echo "\${dev}p\${part}"
    else
        echo "\${dev}\${part}"
    fi
}

# Set root password
echo "Setting root password..."
passwd

# Create user
echo "Creating user $USERNAME..."
useradd -m -g users -G tty,input,video,audio,optical,storage,wheel "$USERNAME"

# Set user password
echo "Setting password for $USERNAME..."
passwd "$USERNAME"

# Install  packages
echo "Installing essential packages..."
pacman -S --noconfirm base efibootmgr git grub linux linux-firmware linux-headers lvm2 neovim networkmanager sudo

# Configure sudo
echo "Configuring sudo..."
echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers

# Configure mkinitcpio for encryption
echo "Configuring initramfs for encryption..."
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf

# Generate initramfs
mkinitcpio -p linux

# Configure locale
echo "Configuring locale..."
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Configure GRUB
echo "Configuring GRUB..."
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet cryptdevice=/dev/\$(get_partition 3):vg_system\"|" /etc/default/grub
# log the line written into the file
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet cryptdevice=/dev/\$(get_partition 3):vg_system\"" >> /etc/default/grub

# Setup EFI partition
mkdir -p /boot/EFI
mount "/dev/\$(get_partition 1)" /boot/EFI

# Install GRUB
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck

# Generate GRUB configuration
mkdir -p /boot/grub/locale
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo 2>/dev/null || true
grub-mkconfig -o /boot/grub/grub.cfg

# Enable NetworkManager
systemctl enable NetworkManager

echo "Configuration complete!"
EOF

# Make the script executable
chmod +x /mnt/setup_chroot.sh

# Run the configuration script in chroot
print_status "Running system configuration (you will be prompted for passwords)..."
arch-chroot /mnt /setup_chroot.sh

# Clean up
rm /mnt/setup_chroot.sh

# ===========================================
# FINALIZATION
# ===========================================

print_status "Unmounting partitions..."
umount -R /mnt

print_status "Installation complete."
print_warning "Remove the installation media when the system restarts."

for i in {3..1}; do
    echo -ne "\rRebooting in $i seconds..."
done

echo -e "\nRebooting now..."
reboot
