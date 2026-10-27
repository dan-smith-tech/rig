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

# select the target disk
lsblk
read -r -p "Target device to wipe (e.g. sda, nvme0n1): " TARGET_DEVICE
if [ ! -b "/dev/$TARGET_DEVICE" ]; then
    echo "/dev/$TARGET_DEVICE does not exist"
    exit 1
fi

# free and wipe the target disk, including any old lvm
swapoff -a
vgchange -an 2>/dev/null || true
while IFS= read -r part; do
    umount -l "/dev/$part" 2>/dev/null || true
    wipefs -af "/dev/$part"
done < <(lsblk -ln -o NAME "/dev/$TARGET_DEVICE" | tail -n +2)
wipefs -af "/dev/$TARGET_DEVICE"

# create the efi and root partitions
EFI_PART="/dev/$(get_partition "$TARGET_DEVICE" 1)"
ROOT_PART="/dev/$(get_partition "$TARGET_DEVICE" 2)"
parted -s "/dev/$TARGET_DEVICE" \
    mklabel gpt \
    mkpart primary fat32 1MiB 1GiB \
    set 1 esp on \
    mkpart primary ext4 1GiB 100%
udevadm settle

# format and mount the partitions
mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 "$ROOT_PART"
mount "$ROOT_PART" /mnt
mount --mkdir -o umask=0077 "$EFI_PART" /mnt/boot

# pick the microcode package from the cpu vendor
if grep -qm1 'GenuineIntel' /proc/cpuinfo; then
    MICROCODE="intel-ucode"
else
    MICROCODE="amd-ucode"
fi

# bootstrap the base system
pacstrap -K /mnt base linux linux-firmware networkmanager sudo neovim "$MICROCODE"
genfstab -U /mnt >> /mnt/etc/fstab

# set the root and user passwords
arch-chroot /mnt passwd
arch-chroot /mnt useradd -m -G wheel "$USERNAME"
arch-chroot /mnt passwd "$USERNAME"

# allow wheel users to sudo without a password
echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > /mnt/etc/sudoers.d/wheel
chmod 0440 /mnt/etc/sudoers.d/wheel

# set the timezone clock and locales
arch-chroot /mnt bash -s <<'EOF'
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_GB.UTF-8' > /etc/locale.conf
EOF

# install the bootloader and write the loader entry
ROOT_PARTUUID="$(blkid -s PARTUUID -o value "$ROOT_PART")"
arch-chroot /mnt bootctl install
mkdir -p /mnt/boot/loader/entries
cat > /mnt/boot/loader/entries/arch.conf <<EOF
title   arch
linux   /vmlinuz-linux
initrd  /${MICROCODE}.img
initrd  /initramfs-linux.img
options root=PARTUUID=${ROOT_PARTUUID} rw
EOF

# enable networking, time sync, and bootloader updates
arch-chroot /mnt systemctl enable NetworkManager systemd-timesyncd

# unmount and reboot
umount -R /mnt
reboot
