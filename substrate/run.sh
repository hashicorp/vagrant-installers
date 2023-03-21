#!/usr/bin/env bash

# NOTE: This script assumes that the architecture specific
#       launcher has been created prior to running via `make`.

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/substrate/deps.sh"

#### Software dependencies

dep_cache="https://vagrant-public-cache.s3.amazonaws.com/installers/dependencies"

#### Update these as required
#### NOTE: Versions are now defined within the deps.sh file. URLs are maintained here to show
####       origin and identify where to pull sources. Actual sources are cached and pulled from
####       our own store.
curl_file="curl-${curl_version}.tar.gz"                # https://curl.haxx.se/download/curl-${curl_version}.tar.gz
libarchive_file="libarchive-${libarchive_version}.tar.gz"    # https://github.com/libarchive/libarchive/archive/v${libarchive_version}.tar.gz
libffi_file="libffi-${libffi_version}.tar.gz"               # https://github.com/libffi/libffi/releases/download/v3.4.2/libffi-3.4.2.tar.gz ftp://sourceware.org/pub/libffi/libffi-${libffi_version}.tar.gz
libgcrypt_file="libgcrypt-${libgcrypt_version}.tar.bz2"      # https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-${libgcrypt_version}.tar.bz2
libgmp_file="gmp-${libgmp_version}.tar.bz2"               # https://ftp.gnu.org/gnu/gmp/gmp-${libgmp_version}.tar.bz2
libgpg_error_file="libgpg-error-${libgpg_error_version}.tar.bz2" # https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-${libgpg_error_version}.tar.bz2
libiconv_file="libiconv-${libiconv_version}.tar.gz"          # https://mirrors.kernel.org/gnu/libiconv/libiconv-${libiconv_version}.tar.gz
# Need up update gcc version to use libssh2 1.9.0+
libssh2_file="libssh2-${libssh2_version}.tar.gz"           # https://www.libssh2.org/download/libssh2-${libssh2_version}.tar.gz
libxml2_file="libxml2-${libxml2_version}.tar.xz"          # https://gitlab.gnome.org/GNOME/libxml2/-/archive/v2.9.14/libxml2-v2.9.14.tar.gz ftp://xmlsoft.org/libxml2/libxml2-${libxml2_version}.tar.gz
libxslt_file="libxslt-${libxslt_version}.tar.xz"          # https://gitlab.gnome.org/GNOME/libxslt/-/archive/${libxslt_version}/libxslt-v${libxslt_version}.tar.gz ftp://xmlsoft.org/libxml2/libxslt-${libxslt_version}.tar.gz
libyaml_file="yaml-${libyaml_version}.tar.gz"              # http://pyyaml.org/download/libyaml/yaml-${libyaml_version}.tar.gz
openssl_file="openssl-${openssl_version}.tar.gz"          # https://www.openssl.org/source/openssl-${openssl_version}.tar.gz
readline_file="readline-${readline_version}.tar.gz"           # https://ftpmirror.gnu.org/readline/readline-${readline_version}.tar.gz
ruby_file="ruby-${ruby_version}.zip"                    # https://cache.ruby-lang.org/pub/ruby/${ruby_short_version}/ruby-${ruby_version}.zip
xz_file="xz-${xz_version}.tar.gz"                     # https://tukaani.org/xz/xz-${xz_version}.tar.gz
zlib_file="zlib-${zlib_version}.tar.gz"                # http://zlib.net/zlib-${zlib_version}.tar.gz

# Used for centos builds
libxcrypt_file="libxcrypt-v4.4.28.tar.gz" # https://github.com/besser82/libxcrypt/archive/v${VERSION}.tar.gz

function info() {
    local msg_template="${1}\n"
    local i=$(( ${#} - 1 ))
    local msg_args=("${@:2:$i}")
    printf "${msg_template}" "${msg_args[@]}" >&2
}

function error() {
    local msg_template="ERROR: ${1}\n"
    local i=$(( ${#} - 1 ))
    local msg_args=("${@:2:$i}")
    printf "${msg_template}" "${msg_args[@]}" >&2
    exit 1
}

function needs_build() {
    local tracker="${1}"
    local package="${2}"

    # If tracker file doesn't exist, build
    # is required
    if [ ! -f "${tracker}" ]; then
        return 0
    fi

    if [[ "$(< "${tracker}" )" = *"${package}"* ]]; then
        return 1
    fi

    return 0
}

function mark_build() {
    local tracker="${1}"
    local package="${2}"

    printf "%s\n" "${package}" >> "${tracker}"
}

# Verify arguments
if [ "$#" -ne "1" ]; then
    info "Usage: $0 OUTPUT-DIR"
    exit 1
fi

# Get the full path to the output directory
# so we write to the correct final location
output_dir="${1}"
if [ ! -d "${output_dir}" ]; then
    mkdir -p "${output_dir}" || exit
fi
pushd "${output_dir}" > /dev/null || exit
output_dir="$(pwd)" || exit
popd > /dev/null || exit

info "Building Vagrant substrate..."

info " -> Performing setup..."
info "  -> Detecting host system... "
uname=$(uname -a)

if [[ "${uname}" = *"86_64"* ]]; then
    target_arch="x86_64"
elif [[ "${uname}" = *"arm"* ]]; then
    target_arch="arm64"
else
    target_arch="386"
fi

if [[ "${uname}" = *"Linux"* ]]; then
    target_os="linux"
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
    target_ident="${linux_os}_${target_arch}"
else
    target_os="darwin"
    target_ident="darwin_${target_arch}"
fi

# NOTE: We keep a copy in host_ prefixed variables
#       so we can query about the actual host. The
#       target_ prefixed variables may change if the
#       build is targeting something different
host_os="${target_os}"
host_arch="${target_arch}"
host_ident="${target_ident}"

info "  -> Detected host system: %s" "${host_ident}"
info "  -> Readying build directories..."

cache_dir="$(mktemp -d vagrant-substrate.XXXXX)" || exit
pushd "${cache_dir}" > /dev/null || exit
cache_dir="$(pwd)" || exit
popd > /dev/null || exit
build_dir="/opt/vagrant"
base_bindir="${build_dir}/bin"
embed_dir="${build_dir}/embedded"
embed_bindir="${embed_dir}/bin"
embed_libdir="${embed_dir}/lib"
tracker_file="${build_dir}/.tracker"

if [ -z "${ENABLE_REBUILD}" ]; then
    info "   * Rebuild support is currently disabled"
    rm -rf "${build_dir:?}/"* || exit
    rm -f "${tracker_file}" || exit
fi

mkdir -p "${base_bindir}" || exit
mkdir -p "${embed_bindir}" || exit
mkdir -p "${embed_libdir}" || exit
mkdir -p "${output_dir}" || exit

touch "${tracker_file}" || exit

pushd "${cache_dir}" > /dev/null || exit

info " -> Building substrate requirements..."

export PKG_CONFIG_PATH="${embed_dir}/lib/pkgconfig"
export CFLAGS="-I${embed_dir}/include"
export CPPFLAGS="-I${embed_dir}/include"
export LDFLAGS="-L${embed_dir}/lib"

# Default these cross configure variables to empty arrays
cross_configure=()
cross_configure_libffi=()
cross_configure_zlib=()
cross_configure_ruby=()

if [[ "${target_os}" = "darwin" ]]; then
    info  " ** Configuring build for macOS"

    cross_configure_ruby+=(
        "--with-rubylibprefix=${embed_libdir}/ruby"
        "--with-rubyhdrdir=${embed_dir}/include"
        "--includedir=${embed_dir}/include"
        "--oldincludedir=${embed_dir}/include"
        "--enable-rpath"
    )

    # Set the host system value
    build_host="${host_arch}-apple-darwin"

    # If we are cross compiling for an arm64 build, make the required adjustments
    if [ "${MACOS_TARGET}" = "arm64" ]; then
        info "   ** macOS build target architecture: arm64"

        # arm64 requires a deployment target of at least 11
        macos_deployment_target="11.0"
        target_host="arm64-apple-darwin"

        # Modifications required to configure scripts for cross building
        cross_configure+=(
            "--host=${target_host}"
            "--target=${target_host}"
            "--build=${build_host}"
        ) # applicable to most but not all

        cross_configure_libffi+=("--with-gcc-arch=arm64")
        cross_configure_zlib+=("--archs=-arch arm64") # zlib specific configuration
        cross_configure_ruby+=(
            "--with-arch=arm64"
            "--with-rubyarchprefix=${embed_libdir}/ruby/arm64"
            "--with-rubyarchhdrdir=${embed_dir}/include/ruby/arm64"
        ) # ruby specific configuration

        if [ "${target_arch}" != "arm64" ]; then
            # Update the target_ident value which is used for
            # writing our substrate asset.
            target_ident="darwin_arm64"
            info "   ** Target identifier detection override to: %s" "${target_ident}"
            target_arch="arm64"
            info "   ** Target arch detection override to: %s" "${target_arch}"
        fi


        # Set the arch in the compiler and linker
        export CFLAGS="${CFLAGS} -arch arm64"
        export LDFLAGS="${LDFLAGS} -arch arm64"
        export ARCHFLAGS="-arch arm64"
    else # By default we target x86_64
        info "   ** macOS build target architecture: x86_64"

        # Defines the minimum version of macOS to target
        # NOTE: Ruby depends on features only available starting with
        #       10.13. Check if we can pull in the 10.9 sdk manually
        #       and build with that.
        macos_deployment_target="10.13"
        target_host="x86_64-apple-darwin"

        # Modifications required to configure scripts for cross building
        cross_configure+=(
            "--host=${target_host}"
            "--target=${target_host}"
            "--build=${build_host}"
        ) # applicable to most but not all

        cross_configure_libffi+=("--with-gcc-arch=x86_64")
        cross_configure_zlib+=("--archs=-arch x86_64") # zlib specific configuration
        cross_configure_ruby+=(
            "--with-arch=x86_64"
            "--with-rubyarchprefix=${embed_libdir}/ruby/x86_64"
            "--with-rubyarchhdrdir=${embed_dir}/include/ruby/x86_64"
        ) # ruby specific configuration

        if [ "${target_arch}" != "x86_64" ]; then
            # Update the target_ident value which is used for
            # writing our substrate asset.
            target_ident="darwin_x86_64"
            info "   ** Target identifier detection override to: %s" "${target_ident}"
            target_arch="x86_64"
            info "   ** Target arch detection override to: %s" "${target_arch}"
        fi

        # Set the arch in the compiler and linker
        export CFLAGS="${CFLAGS} -arch x86_64"
        export LDFLAGS="${LDFLAGS} -arch x86_64"
        export ARCHFLAGS="-arch x86_64"
    fi

    sdk_path="$(xcrun --sdk macosx --show-sdk-path)" || exit

    export MACOSX_DEPLOYMENT_TARGET="${macos_deployment_target}"
    export SDKROOT="${sdk_path}"
    export ISYSROOT="-isysroot ${SDKROOT}"
    export SYSLIBROOT="-syslibroot ${SDKROOT}"
    export SYS_ROOT="${SDKROOT}"
    export CFLAGS="${CFLAGS} -mmacosx-version-min=${macos_deployment_target} ${ISYSROOT}"
    export CXXFLAGS="${CFLAGS}"
    export CPPFLAGS="${CFLAGS}"
    export LDFLAGS="${LDFLAGS} -mmacosx-version-min=${macos_deployment_target} ${ISYSROOT} -Wl,-rpath,${embed_libdir}"
else
    export CFLAGS="${CFLAGS} -fPIC"
    export LDFLAGS="${LDFLAGS} -Wl,-rpath=/opt/vagrant/embedded/lib"
fi

# Now that we have any overrides in place
# for our target, check that the launcher
# has been built and is available
launcher_path="${root}/bin/launcher-${target_os}_${target_arch}"
if [ ! -f "${launcher_path}" ]; then
    error "Vagrant launcher not found, create with 'make bin/launcher/%s-%s' (checked: %s)" \
        "${target_os}" "${target_arch}" "${launcher_path}"
fi

# libxcrypt-compat
# We can't upgrade gcc on 32bit so don't attempt to build libxcrypt
if [ "${linux_os}" = "centos" ]; then
    if [ "${target_arch}" != "386" ]; then
        if needs_build "${tracker_file}" "libxcrypt"; then
            info "   -> Installing libxcrypt-compat..."
            curl -f -L -s -o libxcrypt.tar.gz "${dep_cache}/${libxcrypt_file}" ||
                error "libxcrypt download error encountered"
            tar xzf libxcrypt.tar.gz || exit
            pushd libxcrypt* > /dev/null || exit

            ./autogen.sh || exit
            ./configure --prefix="${embed_dir}" --libdir="${embed_libdir}" || exit
            make || exit
            make install || exit
            mark_build "${tracker_file}" "libxcrypt"
            popd > /dev/null || exit
        fi
    fi
fi

# libffi
if needs_build "${tracker_file}" "libffi"; then
    info "   -> Building libffi..."
    libffi_url="${dep_cache}/${libffi_file}"
    curl -f -L -s -o libffi.tar.gz "${libffi_url}" ||
        error "libffi download error encountered"
    tar -xzf libffi.tar.gz || exit
    pushd libffi-* > /dev/null || exit
    ./configure --prefix="${embed_dir}" --disable-static --enable-shared --disable-debug \
        --enable-portable-binary --disable-docs --disable-dependency-tracking \
        --libdir="${embed_libdir}" "${cross_configure_libffi[@]}" \
        "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "libffi"
    popd > /dev/null || exit
fi

# libiconv
if needs_build "${tracker_file}" "libiconv"; then
    info "   -> Building libiconv..."
    libiconv_url="${dep_cache}/${libiconv_file}"
    curl -f -L -s -o libiconv.tar.gz "${libiconv_url}" ||
        error "libiconv download error encountered"
    tar -xzf libiconv.tar.gz || exit
    pushd libiconv-* > /dev/null || exit
    ./configure --prefix="${embed_dir}" --enable-shared --disable-static --disable-dependency-tracking \
        "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "libiconv"
    popd > /dev/null || exit
fi

## Start - Linux only
if [[ "$(uname -a)" = *"Linux"* ]]; then
    # libgmp
    if needs_build "${tracker_file}" "libgmp"; then
        info "   -> Building libgmp..."
        libgmp_url="${dep_cache}/${libgmp_file}"
        curl -f -L -s -o libgmp.tar.bz2 "${libgmp_url}" ||
            error "libgmp download error encountered"
        tar -xjf libgmp.tar.bz2 || exit
        pushd gmp-* > /dev/null || exit
        if [[ "${target_arch}" = "386" ]]; then
            ABI=32
        else
            ABI=64
        fi
        ./configure --prefix="${embed_dir}" ABI="${ABI}" || exit
        make || exit
        make install || exit
        mark_build "${tracker_file}" "libgmp"
        popd > /dev/null || exit
    fi

    # libgpg_error
    if needs_build "${tracker_file}" "libgpg_error"; then
        info "   -> Building libgpg_error..."
        libgpg_error_url="${dep_cache}/${libgpg_error_file}"
        curl -f -L -s -o libgpg-error.tar.bz2 "${libgpg_error_url}" ||
            error "libgpg-error download error encountered"
        tar -xjf libgpg-error.tar.bz2 || exit
        pushd libgpg-error-* > /dev/null || exit
        ./configure --prefix="${embed_dir}" --enable-shared --disable-static \
            "${cross_configure[@]}" || exit
        make || exit
        make install || exit
        mark_build "${tracker_file}" "libgpg_error"
        popd > /dev/null || exit
    fi

    # libgcrypt
    if needs_build "${tracker_file}" "libgcrypt"; then
        info "   -> Building libgcrypt..."
        libgcrypt_url="${dep_cache}/${libgcrypt_file}"
        curl -f -L -s -o libgcrypt.tar.bz2 "${libgcrypt_url}" ||
            error "libgcrypt download error encountered"
        tar -xjf libgcrypt.tar.bz2 || exit
        pushd libgcrypt-* > /dev/null || exit
        ./configure --prefix="${embed_dir}" --enable-shared --disable-static --disable-asm \
            --disable-doc --with-libgpg-error-prefix="${embed_dir}" "${cross_configure[@]}" || exit
        make || exit
        make install || exit
        mark_build "${tracker_file}" "libgcrypt"
        popd > /dev/null || exit
    fi
fi
## End - Linux only

# xz
if needs_build "${tracker_file}" "xz"; then
    info "   -> Building xz..."
    xz_url="${dep_cache}/${xz_file}"
    curl -f -L -s -o xz.tar.gz "${xz_url}" ||
        error "xz download error encountered"
    tar -xzf xz.tar.gz || exit
    pushd xz-* > /dev/null || exit
    ./configure --prefix="${embed_dir}" --disable-xz --disable-xzdec --disable-dependency-tracking \
        --disable-lzmadec --disable-lzmainfo --disable-lzma-links --disable-scripts \
        --enable-shared --disable-static "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "xz"
    popd > /dev/null || exit
fi

# zlib
if needs_build "${tracker_file}" "zlib"; then
    info "   -> Building zlib..."
    zlib_url="${dep_cache}/${zlib_file}"
    curl -f -L -s -o zlib.tar.gz "${zlib_url}" ||
        error "zlib download error encountered"
    tar -xzf zlib.tar.gz || exit
    pushd zlib-* > /dev/null || exit
    ./configure --prefix="${embed_dir}" \
        "${cross_configure_zlib[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "zlib"
    popd > /dev/null || exit
fi

# libxml2
if needs_build "${tracker_file}" "libxml2"; then
    info "   -> Building libxml2..."
    libxml2_url="${dep_cache}/${libxml2_file}"
    curl -f -L -s -o libxml2.tar.xz "${libxml2_url}" ||
        error "libxml2 download error encountered"
    tar -xf libxml2.tar.xz || exit
    pushd libxml2-* > /dev/null || exit
    ./configure --prefix="${embed_dir}" --disable-dependency-tracking --without-python \
        --without-lzma --with-zlib="${embed_libdir}" --enable-shared \
        --disable-static "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "libxml2"
    popd > /dev/null || exit
fi

# libxslt
if needs_build "${tracker_file}" "libxslt"; then
    info "   -> Building libxslt..."
    libxslt_url="${dep_cache}/${libxslt_file}"
    curl -f -L -s -o libxslt.tar.xz "${libxslt_url}" ||
        error "libxslt download error encountered"
    tar -xf libxslt.tar.xz || exit
    pushd libxslt-* > /dev/null || exit
    rm -f config.sub
    cp ../libxml2-*/config.sub ./config.sub || exit
    OLDLD="${LDFLAGS}"
    export LDFLAGS="${LDFLAGS} -Wl,-undefined,dynamic_lookup" # Required for shared library to build
    ./configure --prefix="${embed_dir}" --enable-shared --disable-static --with-python=no \
        --disable-dependency-tracking --with-libxml-prefix="${embed_dir}" "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "libxslt"
    export LDFLAGS="${OLDLD}"
    popd > /dev/null || exit
fi

# libyaml
if needs_build "${tracker_file}" "libyaml"; then
    info "   -> Building libyaml..."
    libyaml_url="${dep_cache}/${libyaml_file}"
    curl -f -L -s -o libyaml.tar.gz "${libyaml_url}" ||
        error "libyaml download error encountered"
    tar -xzf libyaml.tar.gz || exit
    pushd yaml-* > /dev/null || exit
    rm -f ./config/config.sub
    cp ../libxml2-*/config.sub ./config/config.sub || exit
    ./configure --prefix="${embed_dir}" --disable-dependency-tracking --enable-shared \
        --disable-static "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "libyaml"
    popd > /dev/null || exit
fi

# readline
if needs_build "${tracker_file}" "readline"; then
    info "   -> Building readline..."
    readline_url="${dep_cache}/${readline_file}"
    curl -f -L -s -o readline.tar.gz "${readline_url}" ||
        error "readlin download error encountered"
    tar -xzf readline.tar.gz || exit
    pushd readline-* > /dev/null || exit
    if [[ "${linux_os}" = "archlinux" ]]; then
        CURRENT_LDFLAGS="${LDFLAGS}"
        export LDFLAGS="${LDFLAGS} -lncurses"
    fi
    ./configure --prefix="${embed_dir}" --enable-shared --disable-static \
        "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "readline"
    if [[ "${linux_os}" = "archlinux" ]]; then
        export LDFLAGS="${CURRENT_LDFLAGS}"
    fi
    popd > /dev/null || exit
fi

# openssl
if needs_build "${tracker_file}" "openssl"; then
    info "   -> Building openssl..."
    openssl_url="${dep_cache}/${openssl_file}"
    curl -f -L -f -s -o openssl.tar.gz "${openssl_url}" ||
        error "openssl download error encountered"
    tar -xzf openssl.tar.gz || exit
    pushd openssl-* > /dev/null || exit
    # NOTE: openssl does not provide the option disable the static version of
    #       the library, only the option to enable the shared version
    #       https://github.com/openssl/openssl/issues/8823
    if [ "${MACOS_TARGET}" = "arm64" ]; then
        ./Configure zlib no-asm no-tests shared --prefix="${embed_dir}" darwin64-arm64-cc || exit
    else
        ./config --prefix="${embed_dir}" --libdir=lib --openssldir="${embed_dir}" zlib shared || exit
    fi
    make || exit
    make install_sw || exit
    mark_build "${tracker_file}" "openssl"
    popd > /dev/null || exit
fi

# libssh2
if needs_build "${tracker_file}" "libssh2"; then
    info "   -> Building libssh2..."
    libssh2_url="${dep_cache}/${libssh2_file}"
    curl -f -L -s -o libssh2.tar.gz "${libssh2_url}" ||
        error "libssh2 download error encountered"
    tar -xzf libssh2.tar.gz || exit
    pushd libssh2-* > /dev/null || exit
    rm -f config.sub
    cp ../libxml2-*/config.sub ./config.sub || exit
    ./configure --prefix="${embed_dir}" --disable-dependency-tracking --enable-shared \
        --disable-static --with-libssl-prefix="${embed_dir}" "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "libssh2"
    popd > /dev/null || exit
fi

# bsdtar / libarchive
if needs_build "${tracker_file}" "libarchive"; then
    info "   -> Building bsdtar / libarchive..."
    libarchive_url="${dep_cache}/${libarchive_file}"
    curl -f -L -s -o libarchive.tar.gz "${libarchive_url}" ||
        error "libarchive download error encountered"
    tar -xzf libarchive.tar.gz || exit
    pushd libarchive-* > /dev/null || exit

    ./configure --prefix="${embed_dir}" --disable-dependency-tracking --with-zlib --without-bz2lib \
        --without-iconv --without-libiconv-prefix --without-nettle --without-openssl \
        --without-xml2 --without-expat --enable-shared --disable-static "${cross_configure[@]}" || exit

    # This is a quick hack to work around glibc-2.36 updates that
    # causes problems when attempting to include linux/fs.h. It
    # should be removed once the headers have been syncrhonized
    # https://sourceware.org/glibc/wiki/Synchronizing_Headers
    # https://sourceware.org/glibc/wiki/Release/2.36#Usage_of_.3Clinux.2Fmount.h.3E_and_.3Csys.2Fmount.h.3E
    if [[ "${linux_os}" = "archlinux" ]]; then
        sed -i.bak 's/#include <linux\/mount.h>/\/\/#include <linux\/mount.h>/' /usr/include/linux/fs.h
    fi

    make || exit
    make install || exit
    mark_build "${tracker_file}" "libarchive"
    unset ACLOCAL_PATH
    popd > /dev/null || exit

    # Restore the modified header file
    if [[ "${linux_os}" = "archlinux" ]]; then
        mv /usr/include/linux/fs.h.bak /usr/include/linux/fs.h
    fi
fi

# curl
if needs_build "${tracker_file}" "curl"; then
    info "   -> Building curl..."
    curl_url="${dep_cache}/${curl_file}"
    curl -f -L -s -o curl.tar.gz "${curl_url}" ||
        error "curl download error encountered"
    tar -xzf curl.tar.gz || exit
    pushd curl-* > /dev/null || exit
    ./configure --prefix="${embed_dir}" --disable-dependency-tracking --without-libidn2 \
        --disable-ldap --with-libssh2 --with-ssl --enable-shared --disable-static \
        "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "curl"
    popd > /dev/null || exit
fi

# If we are on darwin, update our shared libraries to make
# them relocatable
if [ "${target_os}" = "darwin" ]; then
    # Update the base libraries
    libcontent=( "${embed_libdir}/"* )
    for libpath in "${libcontent[@]}"; do
        if [[ "${libpath}" != *".dylib" ]]; then
            continue
        fi
        name_id="$(otool -D "${libpath}")" || exit
        name_id="/${name_id#*:*/}"

        # Only modify if it has static path prefix
        if [[ "${name_id}" = "${embed_libdir}/"* ]]; then
            new_id="${name_id#"${embed_libdir}"/}"
            new_id="@rpath/${new_id}"

            info "Updating install name from %s to %s on %s" "${name_id}" "${new_id}" "${libpath}"
            install_name_tool -id "${new_id}" "${libpath}" || exit
        fi

        while IFS= read -rd $'\n' line; do
            if [[ "${line}" = *":" ]]; then
                continue
            fi
            rpath="${line%* (*}"
            rpath="/${rpath#*/}"
            if [[ "${rpath}" = "${embed_libdir}"* ]]; then
                new_rpath="@rpath/${rpath#"${embed_libdir}"/}"
                info "Updating rpath from %s to %s on %s" "${rpath}" "${new_rpath}" "${libpath}"
                install_name_tool -change "${rpath}" "${new_rpath}" "${libpath}"
            fi
        done < <(otool -L "${libpath}")

        # Add rpath entries
        install_name_tool -add_rpath "@executable_path/../lib" "${libpath}"
        install_name_tool -add_rpath "@loader_path" "${libpath}"
        install_name_tool -add_rpath "${embed_libdir}" "${libpath}"

        # TODO: need to update engines files
    done
fi

# ruby
if needs_build "${tracker_file}" "ruby"; then
    info "   -> Building ruby..."
    ruby_url="${dep_cache}/${ruby_file}"
    curl -f -L -s -o ruby.zip "${ruby_url}" ||
        error "ruby download error encountered"
    unzip -q ruby.zip || exit
    pushd ruby-* > /dev/null || exit
    # NOTE: Ruby uses downcased environment variables for appending. If upcased
    #       variables are used, they are a full replacement
    export cflags="${CFLAGS}"
    export cppflags="${CPPFLAGS}"
    export cxxflags="${CXXFLAGS}"
    unset CFLAGS
    unset CPPFLAGS
    unset CXXFLAGS
    ./configure --prefix="${embed_dir}" --disable-debug --disable-dependency-tracking --disable-install-doc \
        --enable-shared --disable-static --with-opt-dir="${embed_dir}" --enable-load-relative --with-sitedir=no \
        --with-vendordir=no --with-sitearchdir=no --with-vendorarchdir=no --with-openssl-dir="${embed_dir}" \
        "${cross_configure[@]}" "${cross_configure_ruby[@]}" || exit
    make miniruby || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "ruby"
    popd > /dev/null || exit
fi

# In some cases we end up with duplicate installations
# of some ruby stuff in the bare lib directory. If they
# exist, remove them.
if [ -d "${embed_libdir}/gems" ]; then
    rm -rf "${embed_libdir}/gems"
fi

check_dirs=( "${embed_libdir}/3."* )
if [ -d "${check_dirs[0]}" ]; then
    rm -rf "${check_dirs[0]}"
fi

# We need to muck with the generated rbconfig.rb file
# to adjust how paths are built so they use the topdir
# instead of static paths. This will allow for relocation
# and let things like a `gem install` still function
# correctly (This is macos only, at least for now)
if [ "${target_os}" = "darwin" ]; then
    rbconf_files=( "${embed_dir}/lib/ruby/3."*/*-darwin*/rbconfig.rb )
    rbconfig_file="${rbconf_files[0]}"

    if [ ! -f "${rbconfig_file}" ]; then
        error "Failed to locate rbconfig.rb file for required modification"
    fi

    info "Updating rbconfig.rb file"
    rbconfig_file_new="${cache_dir}/rbconfig.rb"
    # If the new file exists for some reason, remove it
    rm -f "${rbconfig_file_new}"
    # And make sure it exists
    touch "${rbconfig_file_new}" || exit
    while read -r line; do
        # Only adjust paths when not the prefix value or the
        # original configure arguments
        if [[ "${line}" != *'CONFIG["prefix"]'* ]] && [[ "${line}" != *'CONFIG["configure_args"]'* ]]; then
            line="${line//"${embed_dir}"/\$(prefix)}"
        fi
        printf "%s\n" "${line}" >> "${rbconfig_file_new}"
    done < "${rbconfig_file}"
    mv -f "${rbconfig_file_new}" "${rbconfig_file}" || exit
fi

# Update the rpath in any bundles that ruby created
if [ "${target_os}" = "darwin" ]; then
    while IFS= read -rd '' bundle; do
        info "Updating rpath on bundle file: %s" "${bundle}"
        install_name_tool -add_rpath "@executable_path/../lib/" "${bundle}"
        install_name_tool -add_rpath "@loader_path/" "${bundle}"
        install_name_tool -add_rpath "${embed_libdir}/" "${bundle}"
    done < <( find "${embed_libdir}" -name "*.bundle" )
fi

# Install the launcher
info "   -> Installing vagrant launcher..."
cp "${launcher_path}" "${build_dir}/bin/vagrant" || exit

# install gemrc file
info " -> Writing default gemrc file..."
mkdir -p "${embed_dir}/etc"
cp "${root}/substrate/common/gemrc" "${embed_dir}/etc/gemrc" || exit

# cacert
info " -> Writing cacert.pem..."
curl -f -s --time-cond /vagrant/cacert.pem -o ./cacert.pem "${dep_cache}/cacert.pem" ||
    error "cacert.pem download error encountered"
mv ./cacert.pem "${embed_dir}/cacert.pem" || exit

info " -> Cleaning cruft..."
rm -rf "${embed_dir}"/{certs,misc,private,openssl.cnf,openssl.cnf.dist}
rm -rf "${embed_dir}/share"/{info,man,doc,gtk-doc}
rm -f "${tracker_file}"

# package up the substrate
info " -> Packaging substrate..."
output_file="${output_dir}/substrate_${target_ident}.zip"
pushd "${build_dir}" > /dev/null || exit
zip -q -r "${output_file}" . || exit
popd > /dev/null || exit

info " -> Cleaning up..."
rm -rf "${cache_dir}"
rm -rf "${build_dir}"

info "Substrate build complete: ${output_file}"
