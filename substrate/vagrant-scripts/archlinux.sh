#!/bin/sh

sudo rm -rf /etc/pacman.d/gnupg
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --refresh-keys --keyserver keyserver.ubuntu.com
sudo pacman -Sc --noconfirm
sudo pacman -Syy --noconfirm archlinux-keyring || exit 1
sudo pacman -Syyu --noconfirm || exit 1

# Ensure keys are up-to-date
# sudo pacman-key --refresh-keys
# Ensure the dev tools are installed
sudo pacman --noconfirm -Suy base-devel ruby  || exit 1

OUTPUT_DIR="${VAGRANT_SUBSTRATE_OUTPUT_DIR:-substrate-assets}"
mkdir -p /vagrant/${OUTPUT_DIR}
chmod 755 /vagrant/substrate/run.sh

set -e

/vagrant/substrate/run.sh /vagrant/${OUTPUT_DIR}
