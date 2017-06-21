#!/usr/bin/env bash
set -e

# Verify arguments
if [ "$#" -ne "2" ]; then
    echo "Usage: $0 SUBSTRATE-DIR VAGRANT-VERSION" >&2
    exit 1
fi

SUBSTRATE_DIR=$1
VAGRANT_VERSION=$2

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

cp "${DIR}/archlinux/PKGBUILD" ./PKGBUILD
sed -i "s/%VERSION%/${VAGRANT_VERSION}/" ./PKGBUILD
tar -cf ./package.tar "${SUBSTRATE_DIR}"
sed -i "s/%VAGRANTPATH%/package.tar/" ./PKGBUILD

sudo -u vagrant makepkg --force --noconfirm
