#!/usr/bin/env bash

function fail() {
    echo "ERROR: ${1}"
    exit 1
}

# Verify arguments
if [ "$#" -ne "1" ]; then
  echo "Usage: $0 SUBSTRATE-PATH" >&2
  exit 1
fi

SUBSTRATE_PATH="${1}"
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

check_file="$(date "+/%Y-%m-%d.stamp")"
if [ ! -f "${check_file}" ]; then
    apt-get update ||
        fail "Failed to update local repositories"
    touch "${check_file}"
fi
apt-get install -y libcairo2-dev build-essential ca-certificates ||
    fail "Failed to install required packages"

# Get vagrant version
cp "${gem_path}" vagrant.gem || fail "Failed to relocate Vagrant Gem"
gem unpack ./vagrant.gem || fail "Failed to unpack Vagrant gem"
VAGRANT_VERSION="$(<vagrant/version.txt)"
rm -rf ./vagrant

# Copy in our substrate asset
cp "${SUBSTRATE_PATH}" ./substrate.zip ||
    fail "Failed to copy substrate asset"

unzip ./substrate.zip ||
    fail "Failed to unpack substrate"
mkdir ./vagrant ||
    fail "Failed to create vagrant directory"
mv ./embedded ./vagrant/usr ||
    fail "Failed to rename substrate directory"
rm -f ./substrate.zip

pushd ./vagrant/usr/lib ||
    fail "Could not enter lib directory"

for f in ./*.so; do
    echo "Found shared library: ${f}"
    for ff in "${f}"*; do
        if [ "${f}" = "${ff}" ]; then
            continue
        fi
        echo "  ${f} -> ${ff}"
        rm "${ff}"
        ln -s "${f}" "${ff}"
    done
done
rm -f ./*.a

popd ||
    fail "Could not return to work directory"

# Copy in required files
cp "${appimg_dir}/vagrant.yml" vagrant.yml ||
    fail "Failed to relocate appimage config"
cp "${appimg_dir}/vagrant_wrapper.sh" vagrant_wrapper.sh ||
    fail "Failed to relocate vagrant wrapper script"


# Create our custom deb package
mkdir -p "vagrant/DEBIAN/"
cat <<EOF > vagrant/DEBIAN/control
Package: vagrant
Version: ${VAGRANT_VERSION}-1
Section: utils
Priority: important
Essential: yes
Architecture: amd64
Depends: ca-certificates
Maintainer: HashiCorp Vagrant Team <team-vagrant@hashicorp.com>
Description: Vagrant is a tool for building and distributing development environments.
EOF

dpkg-deb -b ./vagrant || fail "Failed to create Vagrant stub package"
rm -rf ./vagrant/
VAGRANT_DEB_FILE="${WORK_DIR}/vagrant_${VAGRANT_VERSION}-1.deb"
mv ./*.deb "${VAGRANT_DEB_FILE}"

export VAGRANT_VERSION
export WORK_DIR
export VAGRANT_DEB_FILE

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
# rm -rf "${WORK_DIR}"
