#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


set -e

/vagrant/package/appimage.sh "/vagrant/substrate-assets/substrate_ubuntu_$(uname -m).zip"

pkg_dir=${VAGRANT_PACKAGE_OUTPUT_DIR:-"pkg"}
mkdir -p "/vagrant/${pkg_dir}"
chown vagrant:vagrant ./*.zip
mv ./*.zip "/vagrant/${pkg_dir}"
