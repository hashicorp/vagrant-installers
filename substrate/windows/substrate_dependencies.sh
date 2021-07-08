#!/usr/bin/bash

echo "Updating host packages before building substrate"

rm -rf /etc/pacman.d/gnupg

pacman-key --init --keyserver https://keyserver.ubuntu.com/
pacman-key --populate msys2 --keyserver https://keyserver.ubuntu.com/
pacman-key --refresh-keys --keyserver https://keyserver.ubuntu.com/
pacman -Syu --noconfirm
