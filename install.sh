#!/bin/bash

set -euo pipefail

USERNAME="dan"

# resolve partition name for nvme/mmcblk vs sdX devices
get_partition() {
    local dev="$1" part="$2"
    if [[ "$dev" =~ ^(nvme|mmcblk) ]]; then
        echo "${dev}p${part}"
    else
        echo "${dev}${part}"
    fi
}

# connect over wifi if there is no network
if ! ping -c 1 -W 2 archlinux.org > /dev/null 2>&1; then
    echo "no connection, use iwctl to connect then exit to retry"
    while ! ping -c 1 -W 2 archlinux.org > /dev/null 2>&1; do
        iwctl
    done
fi

# select the target disk
echo
lsblk
echo
read -r -p "Target device to wipe (e.g. sda, nvme0n1): " TARGET_DEVICE
if [ ! -b "/dev/$TARGET_DEVICE" ]; then
    echo "/dev/$TARGET_DEVICE does not exist"
    exit 1
fi
lsblk "/dev/$TARGET_DEVICE"
echo

# free and wipe the target disk
swapoff -a
while IFS= read -r part; do
    umount -l "/dev/$part" 2>/dev/null || true
done < <(lsblk -ln -o NAME "/dev/$TARGET_DEVICE" | tail -n +2)
sgdisk --zap-all "/dev/$TARGET_DEVICE"

# create the efi and root partitions
EFI_PART="/dev/$(get_partition "$TARGET_DEVICE" 1)"
ROOT_PART="/dev/$(get_partition "$TARGET_DEVICE" 2)"
parted -s "/dev/$TARGET_DEVICE" \
    mklabel gpt \
    mkpart primary fat32 1MiB 1GiB \
    mkpart primary ext4 1GiB 100%
partprobe "/dev/$TARGET_DEVICE"

# format and mount the partitions
mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 "$ROOT_PART"
mount "$ROOT_PART" /mnt
mkdir /mnt/boot
mount "$EFI_PART" /mnt/boot

# pick the microcode package from the cpu vendor
if grep -qm1 'GenuineIntel' /proc/cpuinfo; then
    MICROCODE="intel-ucode"
else
    MICROCODE="amd-ucode"
fi

# bootstrap the base system
pacstrap /mnt base linux linux-firmware networkmanager sudo neovim "$MICROCODE"
genfstab -U /mnt >> /mnt/etc/fstab

# set the root and user passwords
arch-chroot /mnt passwd
arch-chroot /mnt useradd -m -g users -G tty,input,video,audio,optical,storage,wheel "$USERNAME"
arch-chroot /mnt passwd "$USERNAME"

# allow wheel users to sudo without a password
arch-chroot /mnt bash -c 'echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel'

# set the timezone locales and keymap
arch-chroot /mnt bash -s <<'EOF'
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
echo 'Europe/Zurich' > /etc/timezone
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_GB.UTF-8' > /etc/locale.conf
echo 'KEYMAP=intl' > /etc/vconsole.conf
EOF

# install the bootloader and write the loader entry
ROOT_UUID="$(blkid -s PARTUUID -o value "$ROOT_PART")"
arch-chroot /mnt bootctl install --boot-path=/boot
echo 'LoaderTimeout 0' > /mnt/boot/loader/loader.conf
mkdir -p /mnt/boot/loader/entries
cat > /mnt/boot/loader/entries/arch.conf <<EOF
title   arch
linux   /vmlinuz-linux
initrd  /${MICROCODE}.img
initrd  /initramfs-linux.img
options root=PARTUUID=${ROOT_UUID} rw
EOF

# enable network management
arch-chroot /mnt systemctl enable NetworkManager

# unmount and reboot
umount -R /mnt
echo

for i in {3..1}; do
    echo -ne "Rebooting in $i seconds...\r"
    sleep 1
done
echo
reboot
