#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


export PATH="/usr/local/bin:$PATH"

# su vagrant -l -c 'brew update'

chmod 755 /vagrant/package/package.sh

set -e

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_darwin_x86_64.zip main

pkg_dir="${VAGRANT_PACKAGE_OUTPUT_DIR:-"pkg"}"
mkdir -p "/vagrant/${pkg_dir}"
cp ./*.dmg "/vagrant/${pkg_dir}"
