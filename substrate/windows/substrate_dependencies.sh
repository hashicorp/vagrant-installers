#!/usr/bin/bash

echo "Updating host packages before building substrate"

rm -rf /etc/pacman.d/gnupg

pacman-key --init --keyserver https://keyserver.ubuntu.com/
pacman-key --populate msys2
pacman-key --refresh-keys
pacman -Syu --noconfirm
