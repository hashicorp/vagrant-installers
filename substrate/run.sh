#!/usr/bin/env bash

#### Software dependencies

dep_cache="https://vagrant-public-cache.s3.amazonaws.com/installers/dependencies"

#### Update these as required

curl_file="curl-7.75.0.tar.gz"                # https://curl.haxx.se/download/curl-${curl_version}.tar.gz
libarchive_file="libarchive-v3.5.1.tar.gz"    # https://github.com/libarchive/libarchive/archive/v${libarchive_version}.tar.gz
libffi_file="libffi-3.3.tar.gz"               # ftp://sourceware.org/pub/libffi/libffi-${libffi_version}.tar.gz
libgcrypt_file="libgcrypt-1.9.2.tar.bz2"      # https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-${libgcrypt_version}.tar.bz2
libgmp_file="gmp-6.2.1.tar.bz2"               # https://ftp.gnu.org/gnu/gmp/gmp-${libgmp_version}.tar.bz2
libgpg_error_file="libgpg-error-1.41.tar.bz2" # https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-${libgpg_error_version}.tar.bz2
libiconv_file="libiconv-1.16.tar.gz"          # https://mirrors.kernel.org/gnu/libiconv/libiconv-${libiconv_version}.tar.gz
# Need up update gcc version to use libssh2 1.9.0+
libssh2_file="libssh2-1.8.0.tar.gz"           # https://www.libssh2.org/download/libssh2-${libssh2_version}.tar.gz
libxml2_file="libxml2-2.9.10.tar.gz"          # ftp://xmlsoft.org/libxml2/libxml2-${libxml2_version}.tar.gz
libxslt_file="libxslt-1.1.34.tar.gz"          # ftp://xmlsoft.org/libxml2/libxslt-${libxslt_version}.tar.gz
libyaml_file="yaml-0.2.5.tar.gz"              # http://pyyaml.org/download/libyaml/yaml-${libyaml_version}.tar.gz
openssl_file="openssl-1.1.1k.tar.gz"          # https://www.openssl.org/source/openssl-${openssl_version}.tar.gz
readline_file="readline-8.0.tar.gz"           # https://ftpmirror.gnu.org/readline/readline-${readline_version}.tar.gz
ruby_file="ruby-2.7.4.zip"                    # https://cache.ruby-lang.org/pub/ruby/${ruby_short_version}/ruby-${ruby_version}.zip
xz_file="xz-5.2.5.tar.gz"                     # https://tukaani.org/xz/xz-${xz_version}.tar.gz
zlib_file="zlib-1.2.11.tar.gz"                # http://zlib.net/zlib-${zlib_version}.tar.gz

# Used for centos builds
m4_file="m4-1.4.18.tar.gz"                # https://ftp.gnu.org/gnu/m4/m4-${VERSION}.tar.gz
automake_file="automake-1.16.3.tar.gz"    # https://ftp.gnu.org/gnu/automake/automake-${VERSION}.tar.gz
libtool_file="libtool-2.4.6.tar.gz"       # https://ftp.gnu.org/gnu/libtool/libtool-${VERSION}.tar.gz
patchelf_file="patchelf-0.9.tar.gz"       # https://nixos.org/releases/patchelf/patchelf-${VERSION}/patchelf-${VERSION}.tar.gz
libxcrypt_file="libxcrypt-v4.4.18.tar.gz" # https://github.com/besser82/libxcrypt/archive/v${VERSION}.tar.gz


macos_deployment_target="10.9"

function echo_stderr {
    (>&2 echo "$@")
}

# Set curl to use updated cert bundle
echo "cacert = /vagrant/cacert.pem" > ~/.curlrc
echo "capath = /usr" >> ~/.curlrc

set -e

# Verify arguments
if [ "$#" -ne "1" ]; then
    echo_stderr "Usage: $0 OUTPUT-DIR"
    exit 1
fi

output_dir=$1

echo_stderr "Building Vagrant substrate..."

echo_stderr " -> Performing setup..."
echo_stderr -n "  -> Detecting host system... "
uname=$(uname -a)

if [[ "${uname}" = *"86_64"* ]]; then
    host_arch="x86_64"
else
    host_arch="i686"
fi

if [[ "${uname}" = *"Linux"* ]]; then
    host_os="linux"
    if [[ -f /etc/centos-release ]]; then
        linux_os="centos"
    elif [[ "$(</etc/lsb-release)" = *"Ubuntu"* ]]; then
        export DEBIAN_FRONTEND=noninteractive
        linux_os="ubuntu"
    elif [[ -f /etc/arch-release ]]; then
        linux_os="archlinux"
    else
        linux_os="linux"
    fi
    host_ident="${linux_os}_${host_arch}"
    install_prefix=""
else
    host_os="darwin"
    host_ident="darwin_${host_arch}"
fi

echo_stderr "${host_ident}"
echo_stderr "  -> Readying build directories..."

cache_dir=$(mktemp -d vagrant-substrate.XXXXX)
build_dir="/opt/vagrant"
base_bindir="${build_dir}/bin"
embed_dir="${build_dir}/embedded"
embed_bindir="${embed_dir}/bin"

rm -rf "${build_dir}"
mkdir -p "${base_bindir}"
mkdir -p "${embed_bindir}"
mkdir -p "${output_dir}"
mkdir -p "${embed_dir}/lib64"

if [ "${host_os}" = "darwin" ]; then
    su vagrant -l -c 'brew install automake autoconf pkg-config'
fi

if [ "${host_os}" = "darwin" ]; then
    su vagrant -l -c 'brew install automake autoconf pkg-config'
fi

setupdir=$(mktemp -d vagrant-substrate-setup.XXXXX)
pushd "${setupdir}"

echo_stderr "  -> Installing any required packages..."
if [[ "${linux_os}" = "ubuntu" ]]; then
    apt-get install -qy build-essential autoconf automake chrpath libtool
fi

if [[ "${linux_os}" = "archlinux" ]]; then
    pacman --noconfirm -Suy unzip
fi

if [[ "${linux_os}" = "centos" ]]; then
    set +e
    # need newer gcc to build libxcrypt-compat package
    echo_stderr "      -> Installing custom gcc..."
    sudo yum install -y centos-release-scl
    sudo yum install -y devtoolset-8-toolchain unzip git zip autoconf
    source /opt/rh/devtoolset-8/enable

    yum -d 0 -e 0 -y install chrpath gcc make perl perl-Thread-Queue
    yum -d 0 -e 0 -y install perl-Data-Dumper
    # Remove openssl dev files to prevent any conflicts when building
    yum -d 0 -e 0 -y remove openssl-devel
    set -e

    echo_stderr "  -> Build and install custom host tools..."

    PATH=/usr/local/bin:$PATH
    export PATH=/usr/local/bin:$PATH

    # m4
    if [[ ! -f "/usr/local/bin/m4" ]]; then
        echo_stderr "   -> Installing custom m4..."
        curl -L -s -o m4.tar.gz "${dep_cache}/${m4_file}"
        tar xzf m4.tar.gz
        pushd m4*
        ./configure --prefix "/usr/local"
        make
        make install
        popd
    fi

    # automake
    if [[ ! -f "/usr/local/bin/automake" ]]; then
        echo_stderr "   -> Installing custom automake..."
        curl -L -s -o automake.tar.gz "${dep_cache}/${automake_file}"
        tar xzf automake.tar.gz
        pushd automake*
        ./configure --prefix "/usr/local"
        make
        make install
        popd
    fi

    # libtool
    if [[ ! -f "/usr/local/bin/libtool" ]]; then
        echo_stderr "   -> Installing custom libtool..."
        curl -L -s -o libtool.tar.gz "${dep_cache}/${libtool_file}"
        tar xzf libtool.tar.gz
        pushd libtool*
        ./configure --prefix "/usr/local"
        make
        make install
        popd
    fi

    # patchelf
    if [[ ! -f "/usr/local/bin/patchelf" ]]; then
        echo_stderr "   -> Installing custom patchelf..."
        curl -L -s -o patchelf.tar.gz "${dep_cache}/${patchelf_file}"
        tar xzf patchelf.tar.gz
        pushd patchelf*
        ./configure --prefix "/usr/local"
        make
        make install
        popd
    fi

    export PATH="/usr/local/bin:$PATH"
fi

if [[ "${host_os}" = "darwin" ]]; then
    pushd "/tmp"
    TRAVIS=1 su vagrant -l -c "brew install libtool"
    popd
fi

popd

pushd "${cache_dir}"

echo_stderr " -> Building substrate requirements..."

export PKG_CONFIG_PATH="${embed_dir}/lib/pkgconfig"
export CFLAGS="-I${embed_dir}/include"
export CPPFLAGS="-I${embed_dir}/include"
export LDFLAGS="-L${embed_dir}/lib"
ORIGINAL_LDFLAGS="${LDFLAGS}"
if [[ "${host_os}" = "darwin" ]]; then
    sdk_root="/Library/Developer/CommandLineTools/SDKs"
    sdk_path="${sdk_root}/MacOSX.sdk"
    versioned_sdk_path="${sdk_root}/MacOSX${macos_deployment_target}.sdk"
    # Check that deployment target sdk exists
    if [ ! -d "${versioned_sdk_path}" ]; then
        echo_stderr " !! Requested macOS SDK version is not available: ${macos_deployment_target}"
        exit 1
    else
        rm -f "${sdk_path}"
        ln -s "${versioned_sdk_path}" "${sdk_path}"
    fi
    export MACOSX_DEPLOYMENT_TARGET="${macos_deployment_target}"
    export SDKROOT="${sdk_path}" #"$(xcrun --sdk macosx --show-sdk-path)"
    export ISYSROOT="-isysroot ${SDKROOT}"
    export SYSLIBROOT="-syslibroot ${SDKROOT}"
    export SYS_ROOT="${SDKROOT}"
    export CFLAGS="${CFLAGS} -mmacosx-version-min=${macos_deployment_target} ${ISYSROOT}"
    export CXXFLAGS="${CFLAGS}"
    export CPPFLAGS="${CFLAGS}"
    export LDFLAGS="${LD_FLAGS} -mmacosx-version-min=${macos_deployment_target} ${ISYSROOT}" # ${SYSLIBROOT}"

    export LD_RPATH="/opt/vagrant/embedded/lib:/opt/vagrant/embedded/lib64"
    libtool="glibtool"
else
    export LDFLAGS="${LDFLAGS} -L${embed_dir}/lib64 -Wl,-rpath=/opt/vagrant/embedded/lib:/opt/vagrant/embedded/lib64"
    libtool="libtool"
fi

# libxcrypt-compat
# We can't upgrade gcc on 32bit so don't attempt to build libxcrypt
if [ "${linux_os}" = "centos" ]; then
    if [ "${host_arch}" != "i686" ]; then
        echo_stderr "   -> Installing libxcrypt-compat..."
        curl -L -s -o libxcrypt.tar.gz "${dep_cache}/${libxcrypt_file}" https://github.com/besser82/libxcrypt/archive/v4.4.18.tar.gz
        tar xzf libxcrypt.tar.gz
        pushd libxcrypt*

        ./autogen.sh
        ./configure --prefix="${embed_dir}" --libdir="${embed_dir}/lib"
        make
        make install
        popd
    fi
fi

# libffi
echo_stderr "   -> Building libffi..."
libffi_url="${dep_cache}/${libffi_file}"
curl -L -s -o libffi.tar.gz "${libffi_url}"
tar -xzf libffi.tar.gz
pushd libffi-*
./configure --prefix="${embed_dir}" --disable-debug --disable-dependency-tracking --libdir="${embed_dir}/lib"
make
make install
popd

# libiconv
echo_stderr "   -> Building libiconv..."
libiconv_url="${dep_cache}/${libiconv_file}"
curl -L -s -o libiconv.tar.gz "${libiconv_url}"
tar -xzf libiconv.tar.gz
pushd libiconv-*
./configure --prefix="${embed_dir}" --disable-dependency-tracking
make
make install
popd

$libtool --finish "${embed_dir}/lib"

## Start - Linux only
if [[ "$(uname -a)" = *"Linux"* ]]; then
    # libgmp
    echo_stderr "   -> Building libgmp..."
    libgmp_url="${dep_cache}/${libgmp_file}"
    curl -L -s -o libgmp.tar.bz2 "${libgmp_url}"
    tar -xjf libgmp.tar.bz2
    pushd gmp-*
    if [[ "${host_arch}" = "i686" ]]; then
        ABI=32
    else
        ABI=64
    fi
    ./configure --prefix="${embed_dir}" ABI=$ABI
    make
    make install
    popd

    # libgpg_error
    echo_stderr "   -> Building libgpg_error..."
    libgpg_error_url="${dep_cache}/${libgpg_error_file}"
    curl -L -s -o libgpg-error.tar.bz2 "${libgpg_error_url}"
    tar -xjf libgpg-error.tar.bz2
    pushd libgpg-error-*
    ./configure --prefix="${embed_dir}" --enable-static
    make
    make install
    popd

    # libgcrypt
    echo_stderr "   -> Building libgcrypt..."
    libgcrypt_url="${dep_cache}/${libgcrypt_file}"
    curl -L -s -o libgcrypt.tar.bz2 "${libgcrypt_url}"
    tar -xjf libgcrypt.tar.bz2
    pushd libgcrypt-*
    ./configure --prefix="${embed_dir}" --enable-static --with-libgpg-error-prefix="${embed_dir}"
    make
    make install
    popd
fi
## End - Linux only

# xz
echo_stderr "   -> Building xz..."
xz_url="${dep_cache}/${xz_file}"
curl -L -s -o xz.tar.gz "${xz_url}"
tar -xzf xz.tar.gz
pushd xz-*
./configure --prefix="${embed_dir}" --disable-xz --disable-xzdec --disable-dependency-tracking --disable-lzmadec --disable-lzmainfo --disable-lzma-links --disable-scripts
make
make install
popd

# libxml2
echo_stderr "   -> Building libxml2..."
libxml2_url="${dep_cache}/${libxml2_file}"
curl -L -s -o libxml2.tar.gz "${libxml2_url}"
tar -xzf libxml2.tar.gz
pushd libxml2-*
./configure --prefix="${embed_dir}" --disable-dependency-tracking --without-python --without-lzma --with-zlib="${embed_dir}/lib"
make
make install
popd

# libxslt
echo_stderr "   -> Building libxslt..."
libxslt_url="${dep_cache}/${libxslt_file}"
curl -L -s -o libxslt.tar.gz "${libxslt_url}"
tar -xzf libxslt.tar.gz
pushd libxslt-*
./configure --prefix="${embed_dir}" --disable-dependency-tracking --with-libxml-prefix="${embed_dir}"
make
make install
popd

# libyaml
echo_stderr "   -> Building libyaml..."
libyaml_url="${dep_cache}/${libyaml_file}"
curl -L -s -o libyaml.tar.gz "${libyaml_url}"
tar -xzf libyaml.tar.gz
pushd yaml-*
./configure --prefix="${embed_dir}" --disable-dependency-tracking
make
make install
popd

# zlib
echo_stderr "   -> Building zlib..."
zlib_url="${dep_cache}/${zlib_file}"
curl -L -s -o zlib.tar.gz "${zlib_url}"
tar -xzf zlib.tar.gz
pushd zlib-*
./configure --prefix="${embed_dir}"
make
make install
popd

# readline
echo_stderr "   -> Building readline..."
readline_url="${dep_cache}/${readline_file}"
curl -L -s -o readline.tar.gz "${readline_url}"
tar -xzf readline.tar.gz
pushd readline-*
if [[ "${linux_os}" = "archlinux" ]]; then
    CURRENT_LDFLAGS="${LDFLAGS}"
    export LDFLAGS="${LDFLAGS} -lncurses"
fi
./configure --prefix="${embed_dir}"
make
make install
if [[ "${linux_os}" = "archlinux" ]]; then
    export LDFLAGS="${CURRENT_LDFLAGS}"
fi
popd

# openssl
echo_stderr "   -> Building openssl..."
openssl_url="${dep_cache}/${openssl_file}"
curl -L -f -s -o openssl.tar.gz "${openssl_url}"
tar -xzf openssl.tar.gz
pushd openssl-*
if [ -z "${LD_RPATH}" ]; then
    CURRENT_LDFLAGS="${LDFLAGS}"
    export LDFLAGS="${ORIGINAL_LDFLAGS} -Wl,-rpath=/opt/vagrant/embedded/lib"
fi
./config --prefix="${embed_dir}" --openssldir="${embed_dir}" shared
make
make install_sw
if [ -z "${LD_RPATH}" ]; then
    export LDFLAGS="${CURRENT_LDFLAGS}"
fi
popd

# libssh2
echo_stderr "   -> Building libssh2..."
libssh2_url="${dep_cache}/${libssh2_file}"
curl -L -s -o libssh2.tar.gz "${libssh2_url}"
tar -xzf libssh2.tar.gz
pushd libssh2-*
./configure --prefix="${embed_dir}" --disable-dependency-tracking --with-libssl-prefix="${embed_dir}"
make
make install
popd

# bsdtar / libarchive
echo_stderr "   -> Building bsdtar / libarchive..."
libarchive_url="${dep_cache}/${libarchive_file}"
curl -L -s -o libarchive.tar.gz "${libarchive_url}"
tar -xzf libarchive.tar.gz
pushd libarchive-*

if [ "${host_os}" = "darwin" ] || [ "${linux_os}" = "archlinux" ]; then
    conf_file=$(<configure.ac)
    if [[ "${conf_file}" != *"AC_PROG_CPP"* ]]; then
        sed -i.old 's/^AM_PROG_CC_C_O/AM_PROG_CC_C_O\'$'\nAC_PROG_CPP/' configure.ac
    fi
fi

if [[ "${host_os}" = "linux" ]]; then
    export PATH=/usr/local/bin:$PATH
    PATH=/usr/local/bin:$PATH
    export ACLOCAL_PATH="-I/usr/local/share/aclocal:/usr/local/share/aclocal-1.13:/usr/local/share/autoconf:/usr/share/autoconf:/usr/share/aclocal"
    rm -f aclocal.m4
    aclocal
    libtoolize --force
    autoheader
    autoreconf -vfi
    ./build/autogen.sh
    rm -f aclocal.m4
    aclocal
    libtoolize --force
    autoheader
    autoreconf -vfi
else
    ./build/autogen.sh
fi

./configure --prefix="${embed_dir}" --disable-dependency-tracking --with-zlib --without-bz2lib \
            --without-iconv --without-libiconv-prefix --without-nettle --without-openssl \
            --without-xml2 --without-expat
make
make install
unset ACLOCAL_PATH
popd

# curl
echo_stderr "   -> Building curl..."
curl_url="${dep_cache}/${curl_file}"
curl -L -s -o curl.tar.gz "${curl_url}"
tar -xzf curl.tar.gz
pushd curl-*
./configure --prefix="${embed_dir}" --disable-dependency-tracking --without-libidn2 --disable-ldap --with-libssh2 --with-ssl
make
make install
popd

# ruby
echo_stderr "   -> Building ruby..."
ruby_url="${dep_cache}/${ruby_file}"
curl -L -s -o ruby.zip "${ruby_url}"
unzip -q ruby.zip
pushd ruby-*
o_cflags="${CFLAGS}"
export CFLAGS="${CFLAGS} -I./include -O3 -std=c99"
./configure --prefix="${embed_dir}" --disable-debug --disable-dependency-tracking --disable-install-doc \
            --enable-shared --with-opt-dir="${embed_dir}" --enable-load-relative
make && make install
export CFLAGS="${o_cflags}"
popd

# go launcher
echo_stderr "   -> Building vagrant launcher..."
export GOPATH="$(mktemp -d)"
export PATH=$PATH:/usr/local/bin:/usr/local/go/bin

mkdir launcher
cp /vagrant/substrate/launcher/* launcher/
pushd launcher
go get github.com/mitchellh/osext
go build -o "${build_dir}/bin/vagrant" main.go
popd

# install gemrc file
echo_stderr " -> Writing default gemrc file..."
mkdir -p "${embed_dir}/etc"
cp /vagrant/substrate/common/gemrc "${embed_dir}/etc/gemrc"

# cacert
echo_stderr " -> Writing cacert.pem..."
curl -s --time-cond /vagrant/cacert.pem -o /vagrant/cacert.pem https://curl.se/ca/cacert.pem
cp /vagrant/cacert.pem "${embed_dir}/cacert.pem"

echo_stderr " -> Cleaning cruft..."
rm -rf "${embed_dir}"/{certs,misc,private,openssl.cnf,openssl.cnf.dist}
rm -rf "${embed_dir}/share"/{info,man,doc,gtk-doc}

# package up the substrate
echo_stderr " -> Packaging substrate..."
output_file="${output_dir}/substrate_${host_ident}.zip"
pushd "${build_dir}"
zip -q -r "${output_file}" .
popd

echo_stderr " -> Cleaning up..."
rm -rf "${cache_dir}"
rm -rf "${build_dir}"

echo_stderr "Substrate build complete: ${output_file}"
