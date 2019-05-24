#!/bin/sh

# Ensure the dev tools are installed
sudo pacman --noconfirm -Suy base-devel ruby

# Expected file mode
chmod 755 /vagrant/package/support/package_archlinux.sh

set -e

# Call the support script directly for building since
# there is no substrate to configure
/vagrant/package/support/package_archlinux.sh ${GIT_BUILD_BRANCH:-master}

pkg_dir=${VAGRANT_PACKAGE_OUTPUT_DIR:-"pkg"}
# And store our new package
mkdir -p /vagrant/${pkg_dir}
cp *.xz /vagrant/${pkg_dir}/
