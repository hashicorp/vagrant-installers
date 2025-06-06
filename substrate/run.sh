#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


# NOTE: This script assumes that the architecture specific
#       launcher has been created prior to running via `make`.

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/substrate/deps.sh"

# This is the default SDK path which should be used within the rbconfig file
MACOS_DEFAULT_SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"

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
libidn2_file="libidn2-${libidn2_version}.tar.gz" # https://ftp.gnu.org/gnu/libidn/
libpsl_file="libpsl-${libpsl_version}.tar.gz"             # https://github.com/rockdaboot/libpsl/releases/tag/
# Need up update gcc version to use libssh2 1.9.0+
libssh2_file="libssh2-${libssh2_version}.tar.gz"           # https://www.libssh2.org/download/libssh2-${libssh2_version}.tar.gz
libunistring_file="libunistring-${libunistring_version}.tar.gz" # https://ftp.gnu.org/gnu/libunistring/
libxml2_file="libxml2-${libxml2_version}.tar.xz"          # https://gitlab.gnome.org/GNOME/libxml2/-/archive/v2.9.14/libxml2-v2.9.14.tar.gz ftp://xmlsoft.org/libxml2/libxml2-${libxml2_version}.tar.gz
libxslt_file="libxslt-${libxslt_version}.tar.xz"          # https://gitlab.gnome.org/GNOME/libxslt/-/archive/${libxslt_version}/libxslt-v${libxslt_version}.tar.gz ftp://xmlsoft.org/libxml2/libxslt-${libxslt_version}.tar.gz
libyaml_file="yaml-${libyaml_version}.tar.gz"              # http://pyyaml.org/download/libyaml/yaml-${libyaml_version}.tar.gz
openssl_file="openssl-${openssl_version}.tar.gz"          # https://www.openssl.org/source/openssl-${openssl_version}.tar.gz
readline_file="readline-${readline_version}.tar.gz"           # https://ftpmirror.gnu.org/readline/readline-${readline_version}.tar.gz
ruby_file="ruby-${ruby_version}.zip"                    # https://cache.ruby-lang.org/pub/ruby/${ruby_short_version}/ruby-${ruby_version}.zip
xz_file="xz-${xz_version}.tar.gz"                     # https://tukaani.org/xz/xz-${xz_version}.tar.gz
zlib_file="zlib-${zlib_version}.tar.gz"                # http://zlib.net/zlib-${zlib_version}.tar.gz
cacert_file="cacert-${cacert_version}.pem"
# Used for centos builds
libxcrypt_file="libxcrypt-${libxcrypt_version}.tar.xz" # https://github.com/besser82/libxcrypt/archive/v${VERSION}.tar.xz

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

function fetch() {
    local local_file="${1?Local file is required}"
    local remote_file="${2?Remote file is required}"
    local checksum="${3}"

    curl -f -L -s -o "${local_file}" "${dep_cache}/${remote_file}" ||
        error "Failed to download remote file (%s)" "${remote_file}"

    if [ -n "${checksum}" ]; then
        validate "${local_file}" "${checksum}"
    fi
}

function validate() {
    local path="${1?File path is required}"
    local checksum="${2?Checksum value is required}"
    local computed=""

    if [ ! -f "${path}" ]; then
        error "Invalid path provided for validation (%s)" "${path}"
    fi

    local shasum_cmd=("shasum" "-a" "256")
    if ! command -v shasum > /dev/null 2>&1 ; then
        shasum_cmd=("sha256sum")
    fi
    shasum_cmd+=("${path}")
    computed="$("${shasum_cmd[@]}")" ||
        error "Failed to generate checksum (%s)" "${path}"
    computed="${computed%% *}"

    if [ "${computed}" != "${checksum}" ]; then
        error "Invalid checksum for %s - expected: %s actual: %s" "${path}" "${checksum}" "${computed}"
    fi
}

# Verify arguments
if [ "$#" -gt "2" ]; then
    info "Usage: $0 OUTPUT-DIR [ARCH]"
    exit 1
fi

# Get the full path to the output directory
# so we write to the correct final location
output_dir="${1?Output directory required}"
if [ ! -d "${output_dir}" ]; then
    mkdir -p "${output_dir}" || exit
fi
pushd "${output_dir}" > /dev/null || exit
output_dir="$(pwd)" || exit
popd > /dev/null || exit

# The second argument is optional and can
# be used to force a target architecture.
# This is currently used for doing 32bit
# builds for centos
forced_arch="${2}"

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
    if [ -f /etc/centos-release ]; then
        linux_os="centos"
    elif [ -f /etc/lsb-release ] && [[ "$(</etc/lsb-release)" = *"Ubuntu"* ]]; then
        export DEBIAN_FRONTEND=noninteractive
        linux_os="ubuntu"
    elif [ -f /etc/arch-release ]; then
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

build_dir="/opt/vagrant"
base_bindir="${build_dir}/bin"
embed_dir="${build_dir}/embedded"
embed_bindir="${embed_dir}/bin"
embed_libdir="${embed_dir}/lib"
tracker_file="${build_dir}/.tracker"

if [ -z "${ENABLE_REBUILD}" ]; then
    cache_dir="$(mktemp -d vagrant-substrate.XXXXX)" || exit
    pushd "${cache_dir}" > /dev/null || exit
    cache_dir="$(pwd)" || exit
    popd > /dev/null || exit
    info "   * Rebuild support is currently disabled"
    # Skip build dir removal for darwin; it requires sudo and it is already
    # done in the "Prep filesystem" step in build-macos.yml
    if [[ "${host_os}" != "darwin" ]]; then
        rm -rf "${build_dir:?}" || exit
    fi
else
    info "   * Rebuild support is currently enabled"
    cache_dir="./vagrant-substrate-cache-rebuild-enabled"
    if [ -d "${build_dir}" ] && [ ! -d "${cache_dir}" ]; then
        info "  + Removing existing /opt/vagrant directory"
        rm -rf "${build_dir:?}"
    fi

    mkdir -p "${cache_dir}" || exit
    pushd "${cache_dir}" > /dev/null || exit
    cache_dir="$(pwd)" || exit
    popd > /dev/null || exit
fi

mkdir -p "${base_bindir}" || exit
mkdir -p "${embed_bindir}" || exit
mkdir -p "${embed_libdir}" || exit
mkdir -p "${output_dir}" || exit

touch "${tracker_file}" || exit

pushd "${cache_dir}" > /dev/null || exit

info " -> Building substrate requirements..."

export PKG_CONFIG_PATH="${embed_dir}/lib/pkgconfig"
export CFLAGS="${CFLAGS} -I${embed_dir}/include"
export CPPFLAGS="${CPPFLAGS} -I${embed_dir}/include"
export LDFLAGS="${LDFLAGS} -L${embed_dir}/lib"

# Default these cross configure variables to empty arrays
cross_configure=()
cross_configure_libffi=()
cross_configure_zlib=()
cross_configure_ruby=()

if [ "${target_os}" = "linux" ] && [ -n "${forced_arch}" ]; then
    info " ** Configuring build for forced architecture (%s)" "${forced_arch}"

    # Set the build to what we are actually building on. Define
    # the target with the forced architecture.
    build_host="${host_arch}-linux-gnu"
    target_host="${forced_arch}-linux-gnu"

    if [[ "${forced_arch}" = *"386"* ]] || [[ "${forced_arch}" = *"686"* ]]; then
        target_arch="386"
    elif [[ "${forced_arch}" = *"amd64"* ]] || [[ "${forced_arch}" = *"86"*"64"* ]]; then
        target_arch="x86_64"
    else
        target_arch="${forced_arch}"
    fi
    target_ident="${linux_os}_${target_arch}"

    # Modifications required to configure scripts
    cross_configure+=(
        "--host=${target_host}"
        "--target=${target_host}"
        "--build=${build_host}"
    )

    if [ "${target_arch}" = "386" ]; then
        export CFLAGS="${CFLAGS} -m32 -march=${forced_arch}"
        export LDFLAGS="${LDFLAGS} -m32"
    fi

    info "  ** Build host: %s" "${build_host}"
    info "  ** Target host: %s" "${target_host}"
    info "  ** Target arch: %s" "${target_arch}"
    info "  ** Target ident: %s" "${target_ident}"

    # Add some adjustments so assembly code in the Ruby
    # source is handled properly
    if [ "${target_arch}" = "386" ]; then
        # The following environment variables were required to get
        # Ruby to build properly without throwing errors on when
        # dealing with assembly
        gcc_path="$(command -v gcc)" || exit
        export CC="${gcc_path} -m32"
        export CC_FOR_TARGET="${CC}"
        export CXX="${CC}"
        export CXX_FOR_TARGET="${CC}"
    fi
fi

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

        MACOS_TARGET="x86_64"

        if [ -n "${macos_sdk_file}" ]; then
            info "   ** Custom SDK defined (%s), downloading..." "${macos_sdk_file}"
            pushd "${cache_dir}" > /dev/null || exit
            sdk_path="$(mktemp -d vagrant-substrate.XXXXX)" || exit
            pushd "${sdk_path}" > /dev/null || exit
            sdk_path="$(pwd)" || exit
            fetch sdk.tgz "${macos_sdk_file}" || exit
            tar xf ./sdk.tgz || exit
            files=( ./* )
            for f in "${files[@]}"; do
                if [ -d "${f}" ]; then
                    pushd "${f}" || exit
                    sdk_path="$(pwd)" || exit
                    popd || exit
                fi
            done
            popd > /dev/null || exit
        fi

        if [ -z "${macos_deployment_target}" ]; then
            # Defines the minimum version of macOS to target when not
            # already set. Defaults to 10.13 as this will build correctly
            # on latest
            macos_deployment_target="10.13"
        fi
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

    if [ -z "${sdk_path}" ]; then
        sdk_path="${MACOS_DEFAULT_SDK_PATH}"
    fi

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
    export CXXFLAGS="${CXXFLAGS} ${CFLAGS}"
    export CPPFLAGS="${CPPFLAGS} ${CFLAGS}"
    # NOTE: The weird quoting here is required to get the $ORIGIN value to pass through
    #       unaltered to the linker
    export LDFLAGS="${LDFLAGS} -Wl,-rpath=${embed_libdir}:"'\$$ORIGIN/../lib,--enable-new-dtags'
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
            fetch libxcrypt.tar.gz "${libxcrypt_file}" "${libxcrypt_shasum}" ||
                error "libxcrypt download error encountered"
            tar xf libxcrypt.tar.gz || exit
            pushd libxcrypt* > /dev/null || exit

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
    fetch libffi.tar.gz "${libffi_file}" "${libffi_shasum}" ||
        error "libffi download error encountered"
    tar -xzf libffi.tar.gz || exit
    pushd libffi-* > /dev/null || exit
    ./configure --prefix="${embed_dir}" --disable-static --enable-shared --disable-debug \
        --enable-portable-binary --disable-docs --disable-dependency-tracking \
        --disable-multi-os-directory --libdir="${embed_libdir}" "${cross_configure_libffi[@]}" \
        "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "libffi"
    popd > /dev/null || exit
fi

# libiconv
if needs_build "${tracker_file}" "libiconv"; then
    info "   -> Building libiconv..."
    fetch libiconv.tar.gz "${libiconv_file}" "${libiconv_shasum}" ||
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
        # Current version of libgmp (6.3.0) fails during configure
        # on gcc versions >= 15 due to gcc defaulting to -std=c23.
        # Force to c17 while configuring and revert once done. This
        # can likely be removed on the next update of libgmp.
        if gcc --help=c | grep "std=c23 " > /dev/null; then
            orig_cflags="${CFLAGS}"
            export CFLAGS="${CFLAGS} -std=c17"
        fi

        info "   -> Building libgmp..."
        fetch libgmp.tar.bz2 "${libgmp_file}" "${libgmp_shasum}" ||
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

        export CFLAGS="${orig_cflags}"

        popd > /dev/null || exit
    fi

    # libgpg_error
    if needs_build "${tracker_file}" "libgpg_error"; then
        info "   -> Building libgpg_error..."
        fetch libgpg-error.tar.bz2 "${libgpg_error_file}" "${libgpg_error_shasum}" ||
            error "libgpg-error download error encountered"
        tar -xjf libgpg-error.tar.bz2 || exit
        pushd libgpg-error-* > /dev/null || exit
        ./configure --prefix="${embed_dir}" --enable-shared --disable-static \
            --enable-install-gpg-error-config "${cross_configure[@]}" || exit
        make || exit
        make install || exit
        mark_build "${tracker_file}" "libgpg_error"
        popd > /dev/null || exit
    fi

    # libgcrypt
    if needs_build "${tracker_file}" "libgcrypt"; then
        info "   -> Building libgcrypt..."
        fetch libgcrypt.tar.bz2 "${libgcrypt_file}" "${libgcrypt_shasum}" ||
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
    fetch xz.tar.gz "${xz_file}" "${xz_shasum}" ||
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
    fetch zlib.tar.gz "${zlib_file}" "${zlib_shasum}" ||
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
    fetch libxml2.tar.xz "${libxml2_file}" "${libxml2_shasum}" ||
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
    fetch libxslt.tar.xz "${libxslt_file}" "${libxslt_shasum}" ||
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
    fetch libyaml.tar.gz "${libyaml_file}" "${libyaml_shasum}" ||
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
    fetch readline.tar.gz "${readline_file}" "${readline_shasum}" ||
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

# libunistring
if needs_build "${tracker_file}" "libunistring"; then
    info "   -> Building libunistring..."
    fetch libunistring.tar.gz "${libunistring_file}" "${libunistring_shasum}" ||
        error "libunistring download error encountered"
    tar -xzf libunistring.tar.gz || exit
    pushd libunistring-* > /dev/null || exit
    ./configure --prefix="${embed_dir}" --enable-shared --disable-static \
        "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "libunistring"
    popd > /dev/null || exit
fi

# libidn2
if needs_build "${tracker_file}" "libidn2"; then
    info "   -> Building libidn2..."
    fetch libidn2.tar.gz "${libidn2_file}" "${libidn2_shasum}" ||
        error "libidn2 download error encountered"
    tar -xzf libidn2.tar.gz || exit
    pushd libidn2-* > /dev/null || exit
    ./configure --prefix="${embed_dir}" --enable-shared --disable-static \
        --disable-doc "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "libidn2"
    popd > /dev/null || exit
fi

# libpsl
if needs_build "${tracker_file}" "libpsl"; then
    info "   -> Building libpsl..."
    fetch libpsl.tar.gz "${libpsl_file}" "${libpsl_shasum}" ||
        error "libpsl download error encountered"
    tar -xzf libpsl.tar.gz || exit
    pushd libpsl-* > /dev/null || exit
    ./configure --prefix="${embed_dir}" --enable-shared --disable-static \
        --disable-man --disable-gtk-doc-html "${cross_configure[@]}" || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "libpsl"
    popd > /dev/null || exit
fi

# openssl
#
# NOTE: a variant is defined for linux to build a lib with a custom
#       name (will result in libssl-vagrant.so in this case). this is
#       done to prevent issues when attempting to load the library.
if needs_build "${tracker_file}" "openssl"; then
    info "   -> Building openssl..."
    fetch openssl.tar.gz "${openssl_file}" "${openssl_shasum}" ||
        error "openssl download error encountered"
    tar -xzf openssl.tar.gz || exit
    pushd openssl-* > /dev/null || exit
    # NOTE: openssl does not provide the option disable the static version of
    #       the library, only the option to enable the shared version
    #       https://github.com/openssl/openssl/issues/8823
    if [ "${MACOS_TARGET}" = "arm64" ]; then
        ./Configure zlib no-asm no-tests shared --prefix="${embed_dir}" --libdir=lib --openssldir="${embed_dir}" darwin64-arm64-cc || exit
    elif [ "${MACOS_TARGET}" = "x86_64" ]; then
        ./Configure zlib no-asm no-tests shared --prefix="${embed_dir}" --libdir=lib --openssldir="${embed_dir}" darwin64-x86_64-cc || exit
    elif [ "${target_os}" = "linux" ] && [ "${target_arch}" = "386" ]; then
        cat <<'EOF' > ./Configurations/99-vagrant.conf
(
    "linux-32" => {
        inherit_from => [ 'linux-generic32' ],
        shlib_variant => "-vagrant",
    }
);
EOF
        ./Configure zlib no-tests shared --prefix="${embed_dir}" --libdir=lib linux-32 || exit
    elif [ "${target_os}" = "linux" ] && [ "${target_arch}" = "x86_64" ]; then
        cat <<'EOF' > ./Configurations/99-vagrant.conf
(
    "linux-64" => {
        inherit_from => [ 'linux-x86_64' ],
        shlib_variant => "-vagrant",
    }
);
EOF
        ./Configure zlib no-tests shared --prefix="${embed_dir}" --libdir=lib --openssldir="${embed_dir}" linux-64 || exit
    else
        ./Configure --prefix="${embed_dir}" --libdir=lib --openssldir="${embed_dir}" zlib shared || exit
    fi
    make || exit
    make install_sw || exit
    mark_build "${tracker_file}" "openssl"
    popd > /dev/null || exit
fi

# libssh2
if needs_build "${tracker_file}" "libssh2"; then
    info "   -> Building libssh2..."
    fetch libssh2.tar.gz "${libssh2_file}" "${libssh2_shasum}" ||
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
    fetch libarchive.tar.gz "${libarchive_file}" "${libarchive_shasum}" ||
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
    fetch curl.tar.gz "${curl_file}" "${curl_shasum}" ||
        error "curl download error encountered"
    tar -xzf curl.tar.gz || exit
    pushd curl-* > /dev/null || exit
    ./configure --prefix="${embed_dir}" --disable-dependency-tracking --without-libidn2 \
        --disable-ldap --with-libssh2 --with-ssl --enable-shared --disable-static \
        --without-nghttp2 --without-nghttp3 \
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
    fetch ruby.zip "${ruby_file}" "${ruby_shasum}" ||
        error "ruby download error encountered"
    unzip -q ruby.zip || exit
    pushd ruby-* > /dev/null || exit

    # When ruby is built with the c23 standard, it results in issues
    # with gem installations later. To prevent this, the standard
    # is downgraded to c17.
    if gcc --help=c | grep "std=c23 " > /dev/null; then
        orig_cflags="${CFLAGS}"
        export CFLAGS="${CFLAGS} -std=c17"
    fi

    # If we are building on centos and the target architecture doesn't
    # match the host we need to build a ruby for the host architecture
    # as it's required for doing a cross compilation
    if [ "${linux_os}" = "centos" ] && [ "${target_arch}" != "${host_arch}" ]; then
        # Only build the host Ruby if one isn't already available
        if [ ! -f "/usr/local/bin/ruby" ]; then
            info "    ** Building Ruby for host to enable cross compile"
            ./configure --disable-debug --disable-install-doc --disable-install-rdoc || exit
            make miniruby || exit
            make || exit
            make install || exit
            popd > /dev/null || exit
            rm -rf ./ruby-* || exit
            unzip -q ruby.zip || exit
            pushd ruby-* > /dev/null || exit
            info "    ** Proceeding to substrate Ruby build"
        fi
    fi
    # NOTE: Ruby uses downcased environment variables for appending. If upcased
    #       variables are used, they are a full replacement
    export cflags="${CFLAGS}"
    export cppflags="${CPPFLAGS}"
    export cxxflags="${CXXFLAGS}"
    unset CFLAGS
    unset CPPFLAGS
    unset CXXFLAGS
    ./configure --prefix="${embed_dir}" --disable-debug --disable-install-doc --disable-install-rdoc \
        --disable-install-capi --enable-shared --disable-static --enable-load-relative --with-sitedir=no \
        --with-vendordir=no --with-sitearchdir=no --with-vendorarchdir=no --with-openssl-dir="${embed_dir}" \
        "${cross_configure[@]}" "${cross_configure_ruby[@]}" || exit
    make miniruby || exit
    make || exit
    make install || exit
    mark_build "${tracker_file}" "ruby"

    export CFLAGS="${orig_cflags}"

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
rbconf_files=( "${embed_dir}/lib/ruby/3."*/*-*/rbconfig.rb )
rbconfig_file="${rbconf_files[0]}"
if [ ! -f "${rbconfig_file}" ]; then
    error "Failed to locate rbconfig.rb file for required modification"
fi

rbconfig_file_new="${cache_dir}/rbconfig.rb"
# If the new file exists for some reason, remove it
rm -f "${rbconfig_file_new}"
# And make sure it exists
touch "${rbconfig_file_new}" || exit

info "Updating rbconfig.rb file"
while read -r line; do
    # Always ignore the prefix and configure arguments entries
    if [[ "${line}" = *'CONFIG["prefix"]'* ]] || [[ "${line}" = *'CONFIG["configure_args"]'* ]]; then
        printf "%s\n" "${line}" >> "${rbconfig_file_new}"
        continue
    fi

    # Replace the embedded directory with the computed prefix value
    line="${line//"${embed_dir}"/\$(prefix)}"
    printf "%s\n" "${line}" >> "${rbconfig_file_new}"
done < "${rbconfig_file}"
mv -f "${rbconfig_file_new}" "${rbconfig_file}" || exit

# If we are on darwin, update the SDK paths
if [ "${target_os}" = "darwin" ]; then
    # If the new file still exists for some reason, remove it
    rm -f "${rbconfig_file_new}"
    # And make sure it exists
    touch "${rbconfig_file_new}" || exit

    # Enable extended glob
    shopt -s extglob || exit
    while read -r line; do
        # Update the SDK paths that are defined if not using the
        # default SDK path
        if [[ "${line}" = *"MacOSX.sdk"* ]] && [[ "${line}" != *"${MACOS_DEFAULT_SDK_PATH}"* ]]; then
            # NOTE: Quoting for string replacement is intentional to properly expand
            #       the variable without adding quotes which can happen based on
            #       inconsistent behavior in various bash versions
            line=${line//-isysroot \/*([^[:space:]])MacOSX.sdk/-isysroot "${MACOS_DEFAULT_SDK_PATH}"}
        fi
        printf "%s\n" "${line}" >> "${rbconfig_file_new}"
    done < "${rbconfig_file}"
    # Disable extended glob
    shopt -u extglob
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
chmod 755 "${build_dir}/bin/vagrant" ||
    error "Failed setting permissions on launcher"

# install gemrc file
info " -> Writing default gemrc file..."
mkdir -p "${embed_dir}/etc"
cp "${root}/substrate/common/gemrc" "${embed_dir}/etc/gemrc" || exit

# cacert
info " -> Writing cacert.pem..."
fetch ./cacert.pem "${cacert_file}" "${cacert_shasum}" ||
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
