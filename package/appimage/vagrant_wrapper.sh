#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

export RUBYLIB=""
export RUBYOPT=""

export VAGRANT_BIN_DIR="${DIR}"
export VAGRANT_USR_DIR="$( cd -P "$( dirname "$VAGRANT_BIN_DIR" )" && pwd )"
export VAGRANT_ROOT_DIR="$( cd -P "$( dirname "$VAGRANT_USR_DIR" )" && pwd )"
export GEM_HOME="${VAGRANT_USR_DIR}/gembundle"
export GEM_PATH="${VAGRANT_USR_DIR}/gembundle"
export RUBYLIB="$( "${VAGRANT_BIN_DIR}/ruby2.4" -e "puts $:.map{|x| ENV['VAGRANT_ROOT_DIR'] + x}.join(':')" )"
if [ "${SSL_CERT_FILE}" = "" ]; then
    export SSL_CERT_FILE="${VAGRANT_ROOT_DIR}/etc/ssl/ca-certificates.crt"
fi
if [ "${CURL_CA_BUNDLE}" = "" ]; then
    export CURL_CA_BUNDLE="${VAGRANT_ROOT_DIR}/etc/ssl/ca-certificates.crt"
fi

new_pkg_config_path="${VAGRANT_ROOT_DIR}/usr/lib/x86_64-linux-gnu/pkgconfig"

if [ "${PKG_CONFIG_PATH}" != "" ]; then
    new_pkg_config_path="${new_pkg_config_path}:${PKG_CONFIG_PATH}"
fi

if [ -x "$(command -v pkg-config)" ]; then
    new_pkg_config_path="${new_pkg_config_path}:$(pkg-config --variable pc_path pkg-config)"
fi

export PKG_CONFIG_PATH="${new_pkg_config_path}"
export VAGRANT_INSTALLER_ENV="1"
export VAGRANT_APPIMAGE="1"
export VAGRANT_INSTALLER_EMBEDDED_DIR="${VAGRANT_ROOT_DIR}"
export NOKOGIRI_USE_SYSTEM_LIBRARIES="1"

# Set these for easier debugging so they show up in the logs
export VAGRANT_PKG_CONFIG_PATH="${PKG_CONFIG_PATH}"
export VAGRANT_RUBYLIB="${RUBYLIB}"

if [ "${VAGRANT_PREFER_SYSTEM_BIN}" != "" -a "${VAGRANT_PREFER_SYSTEM_BIN}" != "0" ]; then
    export PATH="${PATH}:${DIR}"
else
    export PATH="${DIR}:${PATH}"
fi

new_ld_library_path="${LD_LIBRARY_PATH}"

if [ -x "$(command -v ldconfig)" ]; then
    extra_ld_path=$(ldconfig -N -X -v 2>&1 | grep "^/.*:$" | tr -d ":" | tr "\n" ":")
else
    extra_ld_path="/lib:/lib64:/usr/lib:/usr/lib64"
fi

if [ "${extra_ld_path}" != "" ]; then
    new_ld_library_path="${new_ld_library_path}:${extra_ld_path}"
fi

export VAGRANT_APPIMAGE_HOST_LD_LIBRARY_PATH="${extra_ld_path}:${LD_LIBRARY_PATH}"
export VAGRANT_APPIMAGE_LD_LIBRARY_PATH="${new_ld_library_path}"

# Python variables will be set but we don't want them
unset PYTHONHOME
unset PYTHONPATH

"${VAGRANT_BIN_DIR}/ruby2.4" -- "${VAGRANT_USR_DIR}/gembundle/bin/vagrant" "$@"
