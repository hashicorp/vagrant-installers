#!/usr/bin/bash

echo "Building for ${1}"

arch=$1
build_dir="ruby-build-${arch}"

mkdir "${build_dir}"
cp -r ruby-build/. "${build_dir}/"

pushd "${build_dir}"

PKGEXT=".pkg.tar.xz" MINGW_ARCH=$arch makepkg-mingw --nodeps --force --noconfirm
