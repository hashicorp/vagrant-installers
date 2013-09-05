#!/bin/bash

# SET: cl_url
# SET: SIGN_CERT/KEY_PATH

# Install Puppet
curl -L https://raw.github.com/hashicorp/puppet-bootstrap/master/mac_os_x.sh \
    | sudo sh -s

# Install Command line tools
dmg_path=$(mktemp -t cl-dmg)
curl -L -o $dmg_path $cl_url
hdiutil attach -plist ${dmg_path} > /dev/null
mount_point='/Volumes/Command Line Tools (Mountain Lion)'
pkg_path=$(find "${mount_point}" -name '*.mpkg' -mindepth 1 -maxdepth 1)
sudo installer -pkg "${pkg_path}" -target / >/dev/null
hdiutil eject "${mount_point}"

# Install Homebrew
ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"

# Install Git
brew install git

# Install the keys
sudo security import ${SIGN_CERT_PATH} -k /Library/Keychains/System.keychain -t cert -P password -T /usr/bin/pkgbuild -T /usr/bin/productbuild -T /usr/bin/codesign
sudo security import ${SIGN_KEY_PATH} -k /Library/Keychains/System.keychain -t priv -P password -T /usr/bin/pkgbuild -T /usr/bin/productbuild -T /usr/bin/codesign
