#!/bin/bash

export PATH="/usr/local/bin:$PATH"

sudo pip3 install dmgbuild

git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow
su vagrant -l -c 'brew install bash'

# Move the SDK into the developer section
sdk="/Users/vagrant/SDKs/MacOSX10.9.sdk"
if [ -d "${sdk}" ]; then
    mv "${sdk}" /Library/Developer/CommandLineTools/SDKs/
fi

chmod 755 /vagrant/package/package.sh

set -e

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_darwin_x86_64.zip main

pkg_dir=${VAGRANT_PACKAGE_OUTPUT_DIR:-"pkg"}
mkdir -p /vagrant/${pkg_dir}
cp *.dmg /vagrant/${pkg_dir}
