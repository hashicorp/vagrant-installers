#!/bin/sh


# Create our local destination for the assets
mkdir -p /vagrant/substrate-assets
# Ensure our package script is executable
chmod 755 /vagrant/package/package.sh

set -e

/vagrant/package/package.sh "/vagrant/substrate-assets/substrate_centos_$(uname -m).zip main"
pkg_dir=${VAGRANT_PACKAGE_OUTPUT_DIR:-"pkg"}
mkdir -p "/vagrant/${pkg_dir}"
cp ./*.rpm "/vagrant/${pkg_dir}/"
