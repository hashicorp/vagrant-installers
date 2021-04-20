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
sudo pacman --noconfirm -Suy base-devel ruby unzip || exit 1

# Expected file mode
chmod 755 /vagrant/package/support/package_archlinux.sh

set -e

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_archlinux_x86_64.zip main

pkg_dir=${VAGRANT_PACKAGE_OUTPUT_DIR:-"pkg"}
# And store our new package
mkdir -p /vagrant/${pkg_dir}
cp *.zst /vagrant/${pkg_dir}/
