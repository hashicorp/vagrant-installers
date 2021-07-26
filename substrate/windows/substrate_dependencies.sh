#!/usr/bin/bash

echo "Updating host packages before building substrate"

rm -rf /etc/pacman.d/gnupg
rm -rf /var/lib/pacman/sync/*
rm -rf /var/cache/pacman/*

sed -i 's/#CacheDir/CacheDir/' /etc/pacman.conf
sed -i 's/#LogFile/LogFile/' /etc/pacman.conf
#sed -i 's/#DBPath/DBPath/' /etc/pacman.conf

curl -O http://repo.msys2.org/msys/x86_64/msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz
curl -O http://repo.msys2.org/msys/x86_64/msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz.sig
pacman -U --config <(echo) msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz

pacman-key --init --keyserver https://keyserver.ubuntu.com/
echo "keyserver hkp://keyserver.ubuntu.com" >> /etc/pacman.d/gnupg/gpg.conf
pacman-key --populate msys2
pacman-key --refresh-keys
pacman -Syu --noconfirm
