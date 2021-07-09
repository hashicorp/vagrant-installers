#!/usr/bin/env bash
set -e

# Verify arguments
if [ "$#" -ne "2" ]; then
    echo "Usage: $0 SUBSTRATE-DIR VAGRANT-VERSION" >&2
    exit 1
fi

SUBSTRATE_DIR=$1
VAGRANT_VERSION=$2

ORIGIN=$(pwd)

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Work in a temporary directory
TMP_DIR=$(mktemp -d tmp.XXXXXXXXX)
pushd $TMP_DIR
TMP_DIR="$(pwd)"

cp "${DIR}/archlinux/PKGBUILD.local" ./PKGBUILD

tar -f substrate.tar.gz --directory="${SUBSTRATE_DIR}" -cz ./

chown -R vagrant:vagrant "${TMP_DIR}"
su vagrant -l -c "pushd ${TMP_DIR}; makepkg --syncdeps --force --noconfirm"

if [ "${CLEAN_VAGRANT_VERSION}" != "" ]; then
    VAGRANT_VERSION=$CLEAN_VAGRANT_VERSION
fi

mv *.zst "${ORIGIN}/vagrant_${VAGRANT_VERSION}_x86_64.tar.zst"

popd
rm -rf "${TMP_DIR}"
