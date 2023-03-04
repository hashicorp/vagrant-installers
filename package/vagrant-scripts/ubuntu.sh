#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


# Force a DNS update
echo "dns-nameservers 8.8.8.8" >> /etc/network/interfaces
service network-interface restart INTERFACE=eth0

set -e

/vagrant/package/package.sh "/vagrant/substrate-assets/substrate_ubuntu_$(uname -m).zip" main

pkg_dir="${VAGRANT_PACKAGE_OUTPUT_DIR:-"pkg"}"
mkdir -p "/vagrant/${pkg_dir}"
cp ./*.deb "/vagrant/${pkg_dir}/"
