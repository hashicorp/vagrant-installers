#!/bin/sh

# Expected file mode
chmod 755 /vagrant/package/support/package_archlinux.sh

set -e

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_archlinux_x86_64.zip main

pkg_dir="${VAGRANT_PACKAGE_OUTPUT_DIR:-"pkg"}"
# And store our new package
mkdir -p "/vagrant/${pkg_dir}"
cp ./*.zst "/vagrant/${pkg_dir}/"
