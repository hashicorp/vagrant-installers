#!/usr/bin/bash

echo "Updating host packages before building substrate"

rm -rf /etc/pacman.d/gnupg
rm -rf /var/lib/pacman/sync/*

pacman-key --init --keyserver https://keyserver.ubuntu.com/
echo "keyserver hkp://keyserver.ubuntu.com" >> /etc/pacman.d/gnupg/gpg.conf
pacman-key --populate msys2

# Add new signer
# TODO check on installer update if can be safely removed
curl "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x87771331b3f1ff5263856a6d974c8be49078f532" -o key
pacman-key -a ./key --gpgdir /etc/pacman.d/gnupg
pacman-key --refresh-keys

pacman -Syu --noconfirm
