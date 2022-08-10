#!/usr/bin/env bash

function fail() {
    echo "ERROR: ${1}"
    exit 1
}

ORIGIN_DIR="$(pwd)"

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

export DEBIAN_FRONTEND=noninteractive

appimg_dir="${DIR}/appimage"
gp=("${DIR}/vagrant"*.gem)
gem_path="${gp[0]}"

# Check for gem and fail is not found
if [ ! -f "${gem_path}" ]; then
    echo "Required Vagrant RubyGem not found!"
    exit 1
fi

WORK_DIR="$(mktemp -d tmp.XXXXXXXXX -p "$(pwd)")"
pushd "${WORK_DIR}" || fail "Could not enter work directory"

# Copy in required files
cp "${gem_path}" vagrant.gem || fail "Failed to relocate Vagrant Gem"
cp "${appimg_dir}/vagrant.yml" vagrant.yml ||
    fail "Failed to relocate appimage config"
cp "${appimg_dir}/vagrant_wrapper.sh" vagrant_wrapper.sh ||
    fail "Failed to relocate vagrant wrapper script"

# Add repository so we can get recent Ruby packages
add-apt-repository -y ppa:brightbox/ruby-ng ||
    fail "Failed to add brightbox repository"
apt-get update ||
    fail "Failed to update local repositories"
apt-get install -y build-essential ca-certificates ruby2.7 ruby2.7-dev ||
    fail "Failed to install required packages"

# Get vagrant version
gem2.7 unpack ./vagrant.gem || fail "Failed to unpack Vagrant gem"
VAGRANT_VERSION="$(<vagrant/version.txt)"
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
Depends: ruby2.7, ruby2.7-dev
Maintainer: HashiCorp Vagrant Team <team-vagrant@hashicorp.com>
Description: Vagrant is a tool for building and distributing development environments.
EOF

dpkg-deb -b ./vagrant || fail "Failed to create Vagrant stub package"
rm -rf ./vagrant/
DEB_FILE="${WORK_DIR}/vagrant_${VAGRANT_VERSION}-1.deb"
mv ./*.deb "${DEB_FILE}"

export WORK_DIR
export DEB_FILE

# Build our appimage
"${appimg_dir}/pkg2appimage" ./vagrant.yml ||
    fail "Failed to build Vagrant appimage"

# Create the release asset
mkdir release-asset
mv out/* release-asset/vagrant ||
    fail "Failed to relocate Vagrant appimage for compression"
zip -j "vagrant_${VAGRANT_VERSION}_linux_amd64.zip" release-asset/* ||
    fail "Failed to create final Vagrant appimage asset"

# Place asset in original execution directory
mv ./*.zip "${ORIGIN_DIR}/" ||
    fail "Failed to move Vagrant appimage asset to destination"

# Exit the directory and clean it
# (we really don't care if this fails)
# shellcheck disable=SC2164
popd
rm -rf "${WORK_DIR}"
