#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


sudo pacman --noconfirm -Sy base-devel

sudo pacman --noconfirm -U https://archive.archlinux.org/packages/r/ruby/ruby-2.2.4-1-x86_64.pkg.tar.xz
sudo pacman --noconfirm -U https://archive.archlinux.org/packages/b/boost-libs/boost-libs-1.63.0-2-x86_64.pkg.tar.xz
sudo pacman --noconfirm -U --force -dd -b /tmp https://archive.archlinux.org/packages/o/openssl/openssl-1.0.2.e-1-x86_64.pkg.tar.xz

sudo gem install --no-document puppet syck

sudo sed -i "s/require 'rubygems'/require 'rubygems'\nrequire 'syck'/" /root/.gem/ruby/2.2.0/bin/puppet

echo "#!/bin/sh\nexport PATH=/root/.gem/ruby/2.2.0/bin:$PATH\n" > /tmp/gem-bin.sh
sudo mv /tmp/gem-bin.sh /etc/profile.d/gem-bin.sh
sudo chmod 755 /etc/profile.d/gem-bin.sh
