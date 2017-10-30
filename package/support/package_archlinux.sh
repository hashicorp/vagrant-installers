#!/usr/bin/env bash
set -e

# Verify arguments
if [ "$#" -ne "1" ]; then
    echo "Usage: $0 VAGRANT-VERSION" >&2
    exit 1
fi

VAGRANT_VERSION=$2

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

cp "${DIR}/archlinux/PKGBUILD" ./PKGBUILD
CLEAN_VAGRANT_VERSION=$(echo $VAGRANT_VERSION | sed 's/^v//')
sed -i "s/%VERSION%/${CLEAN_VAGRANT_VERSION}/" ./PKGBUILD
sed -i "s/%PKGVERSION%/${VAGRANT_VERSION}/" ./PKGBUILD

sudo -u vagrant makepkg --syncdeps --force --noconfirm
