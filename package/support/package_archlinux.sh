#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

function fail() {
    echo "ERROR: ${1}"
    exit 1
}

# Verify arguments
if [ "$#" -ne "2" ]; then
    echo "Usage: $0 SUBSTRATE-DIR VAGRANT-VERSION" >&2
    exit 1
fi

SUBSTRATE_DIR="${1}"
VAGRANT_VERSION="${2}"
ORIGIN="$(pwd)"
if [ -z "${RELEASE_NUMBER}" ]; then
    RELEASE_NUMBER="1"
fi

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Work in a temporary directory
TMP_DIR="$(mktemp -d tmp.XXXXXXXXX -p "$(pwd)")"
pushd "${TMP_DIR}" || fail "Failed to move to temporary working directory"

pacman -Sy || fail "Failed to update package databases"

cp "${DIR}/archlinux/PKGBUILD.local" ./PKGBUILD || fail "Failed to get PKGBUILD file"
sed -i "s/%VAGRANT_VERSION%/${VAGRANT_VERSION}/" ./PKGBUILD ||
    fail "Failed to set Vagrant version into PKGBUILD file"
sed -i "s/%RELEASE_NUMBER%/${RELEASE_NUMBER}/" ./PKGBUILD ||
    fail "Failed to set release number into PKGBUILD file"

tar -f substrate.tar.gz --directory="${SUBSTRATE_DIR}" -cz ./

chown -R vagrant:vagrant "${TMP_DIR}" ||
    fail "Failed to change ownership of temporary working directory"
su vagrant -l -c "pushd ${TMP_DIR}; makepkg --syncdeps --force --noconfirm" ||
    fail "Failed to create package"

if [ "${CLEAN_VAGRANT_VERSION}" != "" ]; then
    VAGRANT_VERSION="${CLEAN_VAGRANT_VERSION}"
fi

mv ./*.zst "${ORIGIN}/vagrant-${VAGRANT_VERSION}-${RELEASE_NUMBER}-x86_64.pkg.tar.zst"

# Exit the directory and clean it
# (we really don't care if this fails)
# shellcheck disable=SC2164
popd
rm -rf "${TMP_DIR}"
