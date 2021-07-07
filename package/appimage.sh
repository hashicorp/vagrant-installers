#!/usr/bin/env bash

set -x

ORIGIN_DIR=$(pwd)

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

export DEBIAN_FRONTEND=noninteractive

appimg_dir="${DIR}/appimage"
gem_path=$(ls "${DIR}"/vagrant*.gem)

# Check for gem and fail is not found
if [ ! -f "${gem_path}" ]; then
    echo "Required Vagrant RubyGem not found!"
    exit 1
fi

set -e

WORK_DIR=$(mktemp -d tmp.XXXXXXXXX)
pushd "${WORK_DIR}"
WORK_DIR=$(pwd)

# Copy in required files
cp "${gem_path}" vagrant.gem
cp "${appimg_dir}/vagrant.yml" vagrant.yml
cp "${appimg_dir}/vagrant_wrapper.sh" vagrant_wrapper.sh

# Get vagrant version
gem unpack ./vagrant.gem
VAGRANT_VERSION=$(cat vagrant/version.txt | sed -e 's/\.[^0-9]*$//')
rm -rf ./vagrant/

# Create our custom deb package
mkdir -p "vagrant/DEBIAN/"
cat <<EOF > vagrant/DEBIAN/control
Package: vagrant
Version: ${VAGRANT_VERSION}-1
Section: utils
Priority: important
Essential: yes
Architecture: amd64
Depends: ruby2.6, ruby2.6-dev
Maintainer: HashiCorp Vagrant Team <team-vagrant@hashicorp.com>
Description: Vagrant is a tool for building and distributing development environments.
EOF

dpkg-deb -b ./vagrant
rm -rf ./vagrant/
DEB_FILE="${WORK_DIR}/vagrant_${VAGRANT_VERSION}-1.deb"
mv *.deb "${DEB_FILE}"

# Add repository so we can get recent Ruby packages
add-apt-repository -y ppa:brightbox/ruby-ng
apt-get update

# Install required packages
apt-get remove --purge -yq ruby2.4 ruby2.4-dev
apt-get autoremove -y
apt-get install -y build-essential ca-certificates ruby2.6 ruby2.6-dev

export WORK_DIR
export DEB_FILE

# Build our appimage
"${appimg_dir}/pkg2appimage" ./vagrant.yml

# Create the release asset
mkdir release-asset
mv out/* release-asset/vagrant
zip -j "vagrant_${VAGRANT_VERSION}_linux_amd64.zip" release-asset/*

# Place asset in original execution directory
mv *.zip "${ORIGIN_DIR}/"
popd

# Clean up after ourself
rm -rf "${WORK_DIR}"
