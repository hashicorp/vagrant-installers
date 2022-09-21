#!/usr/bin/env bash

custom_dir="$(mktemp -d vagrant-substrate.XXXXX)"
pushd "${custom_dir}" || exit 255

#-----

echo "   -> Installing custom autoconf..."
curl -f -L -s -o autoconf.tar.gz "${DEP_CACHE}/autoconf-${AUTOCONF_VERSION}.tar.gz"
tar xf autoconf.tar.gz
pushd autoconf*
./configure --prefix "/usr/local"
make
make install
popd

#-----

echo "   -> Installing custom m4..."
curl -f -L -s -o m4.tar.gz "${DEP_CACHE}/m4-${M4_VERSION}.tar.gz"
tar xzf m4.tar.gz
pushd m4*
./configure --prefix "/usr/local"
make
make install
popd

#-----

echo "   -> Installing custom automake..."
curl -f -L -s -o automake.tar.gz "${DEP_CACHE}/automake-${AUTOMAKE_VERSION}.tar.gz"
tar xzf automake.tar.gz
pushd automake*
./configure --prefix "/usr/local"
make
make install
popd

#-----

echo  "   -> Installing custom libtool..."
curl -f -L -s -o libtool.tar.gz "${DEP_CACHE}/libtool-${LIBTOOL_VERSION}.tar.gz"
tar xzf libtool.tar.gz
pushd libtool*
./configure --prefix "/usr/local"
make
make install
popd

#-----

echo "   -> Installing custom patchelf..."
curl -f -L -s -o patchelf.tar.gz "${DEP_CACHE}/patchelf-${PATCHELF_VERSION}.tar.gz"
tar xzf patchelf.tar.gz
pushd patchelf*
./configure --prefix "/usr/local"
make
make install
popd

echo 'PATH="/usr/local/bin:$PATH"' >> /etc/profile
