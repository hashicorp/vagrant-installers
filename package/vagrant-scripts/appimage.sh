#!/usr/bin/env bash

set -e

# NOTE: Remove this once added to packer template
#       and new box is available
apt-get update
apt-get install -yq libcairo2-dev

/vagrant/package/appimage.sh

mkdir -p /vagrant/pkg
chown vagrant:vagrant *.zip
mv *.zip /vagrant/pkg
