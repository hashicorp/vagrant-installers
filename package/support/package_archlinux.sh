#!/usr/bin/env bash
set -e

# Verify arguments
if [ "$#" -ne "1" ]; then
    echo "Usage: $0 VAGRANT-VERSION" >&2
    exit 1
fi

export VAGRANT_VERSION=$1

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

cp "${DIR}/archlinux/PKGBUILD" ./PKGBUILD
export CLEAN_VAGRANT_VERSION=$(echo $VAGRANT_VERSION | sed 's/^v//' | tr -d ' -')

sudo -E -u vagrant makepkg --syncdeps --force --noconfirm
