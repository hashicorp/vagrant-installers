#!/usr/bin/env bash
set -e

ORIGIN=$(pwd)

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

VAGRANT_GEM_PATH="${DIR}/../vagrant.gem"

# Work in a temporary directory
TMP_DIR=$(mktemp -d tmp.XXXXXXXXX)
pushd $TMP_DIR

if [ -f "${VAGRANT_GEM_PATH}" ]; then
    cp "${VAGRANT_GEM_PATH}" ./vagrant.gem
    gem unpack ./vagrant.gem
    export VAGRANT_VERSION=$(cat vagrant/version.txt | sed -e 's/\.[^0-9]*$//')
    rm -rf ./vagrant
    cp "${DIR}/archlinux/PKGBUILD.local" ./PKGBUILD
    tar -f substrate.tar.gz --directory="${DIR}/../../" -cz substrate/
else
    # Verify arguments
    if [ "$#" -ne "1" ]; then
        echo "Usage: $0 VAGRANT-VERSION" >&2
        exit 1
    fi
    export VAGRANT_VERSION=$1
    export CLEAN_VAGRANT_VERSION=$(echo $VAGRANT_VERSION | sed 's/^v//' | tr -d ' -')
    cp "${DIR}/archlinux/PKGBUILD" ./PKGBUILD
fi

makepkg --syncdeps --force --noconfirm

if [ "${CLEAN_VAGRANT_VERSION}" != "" ]; then
    VAGRANT_VERSION=$CLEAN_VAGRANT_VERSION
fi

mv *.zst "${ORIGIN}/vagrant_${VAGRANT_VERSION}_x86_64.tar.zst"

popd
rm -rf "${TMP_DIR}"
