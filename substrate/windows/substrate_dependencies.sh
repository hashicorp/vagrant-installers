#!/usr/bin/bash

echo "Updating host packages before building substrate"

rm -rf /etc/pacman.d/gnupg

pacman-key --init
pacman-key --populate msys2

# https://github.com/msys2/MSYS2-packages/issues/2225
curl -O http://repo.msys2.org/msys/x86_64/msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz
pacman -U msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz --noconfirm

pacman-key --refresh-keys
pacman -Syu --noconfirm --disable-download-timeout
