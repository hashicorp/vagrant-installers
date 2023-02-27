#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


set -e
set -x

if [ -e /dev/vda ]; then
  device=/dev/vda
elif [ -e /dev/sda ]; then
  device=/dev/sda
else
  echo "ERROR: There is no disk available for installation" >&2
  exit 1
fi
export device

memory_size_in_kilobytes=$(free | awk '/^Mem:/ { print $2 }')
swap_size_in_kilobytes=$((memory_size_in_kilobytes * 2))
sfdisk "$device" <<EOF
label: dos
size=${swap_size_in_kilobytes}KiB, type=82
                                   type=83, bootable
EOF
mkswap "${device}1"
mkfs.ext4 "${device}2"
mount "${device}2" /mnt

curl -fsSL https://www.archlinux.org/mirrorlist/?country=all > /tmp/mirrolist
grep '^#Server' /tmp/mirrolist | sort -R | head -n 50 | sed 's/^#//' > /etc/pacman.d/mirrorlist
#rankmirrors -v /tmp/mirrolist.50 | tee /etc/pacman.d/mirrorlist

systemctl disable sshd
systemctl stop sshd
pacman -Sy --noconfirm archlinux-keyring
pacstrap /mnt base linux linux-firmware grub openssh sudo mkinitcpio dhcpcd

swapon "${device}1"
genfstab -p /mnt >> /mnt/etc/fstab
swapoff "${device}1"

cp /etc/mkinitcpio.d/linux.preset /mnt/etc/mkinitcpio.d/

arch-chroot /mnt /bin/bash
