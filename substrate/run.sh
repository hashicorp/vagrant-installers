#!/usr/bin/env bash

#### Software versions
#### Update these as required

curl_version="7.61.0"
libarchive_version="3.3.2"
libffi_version="3.2.1"
libgcrypt_version="1.8.2"
libgmp_version="6.1.2"
libgpg_error_version="1.27"
libiconv_version="1.15"
libssh2_version="1.8.0"
libxml2_version="2.9.7"
libxslt_version="1.1.32"
libyaml_version="0.1.7"
openssl_version="1.1.0g"
readline_version="7.0"
ruby_version="2.4.6"
xz_version="5.2.3"
zlib_version="1.2.11"

function echo_stderr {
    (>&2 echo "$@")
}

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
    if [[ -f /etc/os-release ]]; then
        linux_os="ubuntu"
    else
        linux_os="centos"
    fi
    host_ident="${linux_os}_${host_arch}"
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

setupdir=$(mktemp -d vagrant-substrate-setup.XXXXX)
pushd "${setupdir}"

echo_stderr "  -> Installing any required packages..."
if [[ "${linux_os}" = "ubuntu" ]]; then
    apt-get install -qy build-essential autoconf automake chrpath libtool
fi

if [[ "${linux_os}" = "centos" ]]; then
    set +e
    # need newer gcc to build libxcrypt-compat package
    echo_stderr "      -> Installing custom gcc..."
    sudo yum install -y centos-release-scl
    sudo yum install -y devtoolset-8-toolchain
    source /opt/rh/devtoolset-8/enable

    yum -d 0 -e 0 -y install chrpath gcc make perl
    yum -d 0 -e 0 -y install perl-Data-Dumper
    # Remove openssl dev files to prevent any conflicts when building
    yum -d 0 -e 0 -y remove openssl-devel
    set -e
fi

if [[ "${linux_os}" != "ubuntu" ]]; then
    echo_stderr "  -> Build and install custom host tools..."

    PATH=/usr/local/bin:$PATH
    export PATH=/usr/local/bin:$PATH

    # m4
    if [[ ! -f "/usr/local/bin/m4" ]]; then
        echo_stderr "   -> Installing custom m4..."
        curl -L -s -o m4.tar.gz http://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.gz
        tar xzf m4.tar.gz
        pushd m4*
        ./configure
        make
        make install
        popd
    fi

    # autoconf
    if [[ ! -f "/usr/local/bin/autoconf" ]]; then
        echo_stderr "   -> Installing custom autoconf..."
        curl -L -s -o autoconf.tar.gz http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
        tar xzf autoconf.tar.gz
        pushd autoconf*
        ./configure
        make
        make install
        popd
    fi

    # automake
    if [[ ! -f "/usr/local/bin/automake" ]]; then
        echo_stderr "   -> Installing custom automake..."
        curl -L -s -o automake.tar.gz http://ftp.gnu.org/gnu/automake/automake-1.16.1.tar.gz
        tar xzf automake.tar.gz
        pushd automake*
        ./configure
        make
        make install
        popd
    fi

    if [[ "${linux_os}" = "centos" ]]; then
        # libtool
        if [[ ! -f "/usr/local/bin/libtool" ]]; then
            echo_stderr "   -> Installing custom libtool..."
            curl -L -s -o libtool.tar.gz http://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.gz
            tar xzf libtool.tar.gz
            pushd libtool*
            ./configure
            make
            make install
            popd
        fi

        # patchelf
        if [[ ! -f "/usr/local/bin/patchelf" ]]; then
            echo_stderr "   -> Installing custom patchelf..."
            curl -L -s -o patchelf.tar.gz https://nixos.org/releases/patchelf/patchelf-0.9/patchelf-0.9.tar.gz
            tar xzf patchelf.tar.gz
            pushd patchelf*
            ./configure
            make
            make install
            popd
        fi

        # libxcrypt-compat
        export PATH="/usr/local/bin:$PATH"
        echo_stderr "   -> Installing libxcrypt-compat..."

        source /opt/rh/devtoolset-8/enable

        curl -L -s -o libxcrypt.tar.gz https://github.com/besser82/libxcrypt/archive/v4.4.6.tar.gz
        tar xzf libxcrypt.tar.gz
        pushd libxcrypt*

        CFLAGSORG=$CFLAGS
        export CFLAGS="-Wno-conversion"
        ./bootstrap
        ./configure --prefix="${embed_dir}"
        make
        make install
        export CFLAGS=$CFLAGSORG
        popd

    fi
fi

if [[ "${host_os}" = "darwin" ]]; then
    pushd "/tmp"
    TRAVIS=1 su vagrant -l -c "brew install libtool"
    popd
fi

popd

pushd "${cache_dir}"

echo_stderr " -> Building substrate requirements..."

export CFLAGS="-I${embed_dir}/include"
export CPPFLAGS="-I${embed_dir}/include"
export LDFLAGS="-L${embed_dir}/lib"
if [[ "${host_os}" = "darwin" ]]; then
    export MACOSX_DEPLOYMENT_TARGET="10.5"
    export LD_RPATH="XORIGIN/../lib:XORIGIN/../lib64:/opt/vagrant/embedded/lib:/opt/vagrant/embedded/lib64"
    libtool="glibtool"
else
    export LDFLAGS="${LDFLAGS} -L${embed_dir}/lib64 -Wl,-rpath=XORIGIN/../lib:XORIGIN/../lib64:/opt/vagrant/embedded/lib:/opt/vagrant/embedded/lib64"
    libtool="libtool"
fi

# libffi
echo_stderr "   -> Building libffi..."
libffi_url="ftp://sourceware.org/pub/libffi/libffi-${libffi_version}.tar.gz"
curl -L -s -o libffi.tar.gz "${libffi_url}"
tar -xzf libffi.tar.gz
pushd libffi-*
./configure --prefix="${embed_dir}" --disable-debug --disable-dependency-tracking --libdir="${embed_dir}/lib"
make
make install
popd

# libiconv
echo_stderr "   -> Building libiconv..."
libiconv_url="http://mirrors.kernel.org/gnu/libiconv/libiconv-${libiconv_version}.tar.gz"
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
    libgmp_url="https://ftp.gnu.org/gnu/gmp/gmp-${libgmp_version}.tar.bz2"
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
    libgpg_error_url="https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-${libgpg_error_version}.tar.bz2"
    curl -L -s -o libgpg-error.tar.bz2 "${libgpg_error_url}"
    tar -xjf libgpg-error.tar.bz2
    pushd libgpg-error-*
    ./configure --prefix="${embed_dir}" --enable-static
    make
    make install
    popd

    # libgcrypt
    echo_stderr "   -> Building libgcrypt..."
    libgcrypt_url="https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-${libgcrypt_version}.tar.bz2"
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
xz_url="https://tukaani.org/xz/xz-${xz_version}.tar.gz"
curl -L -s -o xz.tar.gz "${xz_url}"
tar -xzf xz.tar.gz
pushd xz-*
./configure --prefix="${embed_dir}" --disable-xz --disable-xzdec --disable-dependency-tracking --disable-lzmadec --disable-lzmainfo --disable-lzma-links --disable-scripts
make
make install
popd

# libxml2
echo_stderr "   -> Building libxml2..."
libxml2_url="ftp://xmlsoft.org/libxml2/libxml2-${libxml2_version}.tar.gz"
curl -L -s -o libxml2.tar.gz "${libxml2_url}"
tar -xzf libxml2.tar.gz
pushd libxml2-*
./configure --prefix="${embed_dir}" --disable-dependency-tracking --without-python --without-lzma --with-zlib="${embed_dir}/lib"
make
make install
popd

# libxslt
echo_stderr "   -> Building libxslt..."
libxslt_url="ftp://xmlsoft.org/libxml2/libxslt-${libxslt_version}.tar.gz"
curl -L -s -o libxslt.tar.gz "${libxslt_url}"
tar -xzf libxslt.tar.gz
pushd libxslt-*
./configure --prefix="${embed_dir}" --disable-dependency-tracking --with-libxml-prefix="${embed_dir}"
make
make install
popd

# libyaml
echo_stderr "   -> Building libyaml..."
libyaml_url="http://pyyaml.org/download/libyaml/yaml-${libyaml_version}.tar.gz"
curl -L -s -o libyaml.tar.gz "${libyaml_url}"
tar -xzf libyaml.tar.gz
pushd yaml-*
./configure --prefix="${embed_dir}" --disable-dependency-tracking
make
make install
popd

# zlib
echo_stderr "   -> Building zlib..."
zlib_url="http://zlib.net/zlib-${zlib_version}.tar.gz"
curl -L -s -o zlib.tar.gz "${zlib_url}"
tar -xzf zlib.tar.gz
pushd zlib-*
./configure --prefix="${embed_dir}"
make
make install
popd

# readline
echo_stderr "   -> Building readline..."
readline_url="http://ftpmirror.gnu.org/readline/readline-${readline_version}.tar.gz"
curl -L -s -o readline.tar.gz "${readline_url}"
tar -xzf readline.tar.gz
pushd readline-*
./configure --prefix="${embed_dir}"
make
make install
popd

# openssl
echo_stderr "   -> Building openssl..."
openssl_url="http://www.openssl.org/source/openssl-${openssl_version}.tar.gz"
curl -L -s -o openssl.tar.gz "${openssl_url}"
tar -xzf openssl.tar.gz
pushd openssl-*
./config --prefix="${embed_dir}" --openssldir="${embed_dir}" shared
make
make install_sw
popd

# libssh2
echo_stderr "   -> Building libssh2..."
libssh2_url="http://www.libssh2.org/download/libssh2-${libssh2_version}.tar.gz"
curl -L -s -o libssh2.tar.gz "${libssh2_url}"
tar -xzf libssh2.tar.gz
pushd libssh2-*
./configure --prefix="${embed_dir}" --disable-dependency-tracking --with-libssl-prefix="${embed_dir}"
make
make install
popd

# bsdtar / libarchive
echo_stderr "   -> Building bsdtar / libarchive..."
libarchive_url="https://github.com/libarchive/libarchive/archive/v${libarchive_version}.tar.gz"
curl -L -s -o libarchive.tar.gz "${libarchive_url}"
tar -xzf libarchive.tar.gz
pushd libarchive-*

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
curl_url="https://curl.haxx.se/download/curl-${curl_version}.tar.gz"
curl -L -s -o curl.tar.gz "${curl_url}"
tar -xzf curl.tar.gz
pushd curl-*
./configure --prefix="${embed_dir}" --disable-dependency-tracking --without-libidn2 --disable-ldap --with-libssh2 --with-ssl
make
make install
popd

# ruby
echo_stderr "   -> Building ruby..."
ruby_short_version=$(echo $ruby_version | awk -F. '{print $1"."$2}')
ruby_url="https://cache.ruby-lang.org/pub/ruby/${ruby_short_version}/ruby-${ruby_version}.zip"
curl -L -s -o ruby.zip "${ruby_url}"
unzip -q ruby.zip
pushd ruby-*
./configure --prefix="${embed_dir}" --disable-debug --disable-dependency-tracking --disable-install-doc \
            --enable-shared --with-opt-dir="${embed_dir}" --enable-load-relative
CFLAGS="-I./include -O3" make && make install
popd

# go launcher
echo_stderr "   -> Building vagrant launcher..."
export GOPATH="$(mktemp -d)"
export PATH=$PATH:/usr/local/bin:/usr/local/go/bin

mkdir launcher
cp /vagrant/substrate/launcher/main.go launcher/
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
curl -s --time-cond /vagrant/cacert.pem -o /vagrant/cacert.pem https://curl.haxx.se/ca/cacert.pem
cp /vagrant/cacert.pem "${embed_dir}/cacert.pem"

# rubyencoder
echo_stderr " -> Installing rubyencoder loader..."
mkdir -p "${embed_dir}/rgloader"
cp /vagrant/substrate/common/rgloader/* "${embed_dir}/rgloader"/
cp /vagrant/substrate/${host_os}/rgloader/* "${embed_dir}/rgloader"/

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
