#!/bin/sh

pacman --noconfirm -Sy unzip

mkdir -p /vagrant/substrate-assets
chmod 755 /vagrant/package/package.sh

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_archlinux_$(uname -m).zip master
mkdir -p /vagrant/pkg
cp *.xz /vagrant/pkg/
