#!/usr/bin/env bash

# Error when something goes wrong
set -e

# Upgrade Pacman
pacman -Sy pacman --noconfirm

# Base system
pacman -S base-devel --noconfirm

# Install Ruby
pacman -S ruby --noconfirm

# Install Chef
gem install chef --no-ri --no-rdoc
gem install rake --no-ri --no-rdoc

# Install git
pacman -S git --noconfirm

# Grab the installer sources
git clone git://github.com/mitchellh/vagrant-installers.git
cd vagrant-installers
