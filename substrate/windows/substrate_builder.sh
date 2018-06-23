#!/usr/bin/bash

echo "Running host updates before build"
pacman -Syu --noconfirm

echo "Cleaning cache"
rm -rf /var/cache/pacman/pkg/*

# Create directories for new assets
rm -rf output/vagrant-w64/
rm -rf output/vagrant-w32/

mkdir -p output/vagrant-w64/
mkdir -p output/vagrant-w32/

# Store ruby packages locally
mkdir -p pkgs
RUBYPKGDIR=`cygpath -pu $1`
WORKINGDIR=`pwd`
STAGE32=`cygpath -pu $2`
STAGE64=`cygpath -pu $3`

find $RUBYPKGDIR -name "*.xz" -exec cp {} pkgs/ \;

./styrene.sh --pkg-dir=pkgs --output-dir=output --no-exe --color=no vagrant.cfg

if [ $? -ne 0 ];
then
    echo "Attempting to package again..."
    set -e
    ./styrene.sh --pkg-dir=pkgs --output-dir=output --no-exe --color=no vagrant.cfg
fi

set -ex

# Start with the 64 bit build
mkdir -p substrate
find output/ -name "*w64*.zip" -exec cp {} substrate/substrate-asset.zip \;
pushd substrate
unzip -q substrate-asset.zip
rm -rf _scripts substrate-asset.zip

# The built ruby will have a minimal installation of msys2 and
# will fall back to having cygwin style path mounts to access
# the full windows system. This will "trick" ruby into building
# windows paths using the `/cygdrive` mount instead of the msys2
# style mounts of `/DRIVE`
find ./mingw64/lib/ruby/ -name "*rbconfig.rb" -exec sed -i 's/"build_os".*$/"build_os"] = "cygwin"/' {} \;

find ./ -maxdepth 1 -name "*" -exec rm -rf $STAGE64/embedded/{} \;
find ./ -maxdepth 1 -name "*" -exec mv -f {} $STAGE64/embedded/ \;
popd
rm -rf substrate

# Finish with the 32 bit build
mkdir -p substrate
find output/ -name "*w32*.zip" -exec cp {} substrate/substrate-asset.zip \;
pushd substrate
unzip -q substrate-asset.zip
rm -rf _scripts substrate-asset.zip

# The built ruby will have a minimal installation of msys2 and
# will fall back to having cygwin style path mounts to access
# the full windows system. This will "trick" ruby into building
# windows paths using the `/cygdrive` mount instead of the msys2
# style mounts of `/DRIVE`
find ./mingw32/lib/ruby/ -name "*rbconfig.rb" -exec sed -i 's/"build_os".*$/"build_os"] = "cygwin"/' {} \;

find ./ -maxdepth 1 -name "*" -exec rm -rf $STAGE32/embedded/{} \;
find ./ -maxdepth 1 -name "*" -exec mv -f {} $STAGE32/embedded/ \;
popd
rm -rf substrate
