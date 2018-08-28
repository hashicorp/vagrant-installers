#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

export VAGRANT_BIN_DIR="${DIR}"
export VAGRANT_USR_DIR="${DIR}/../"
export GEM_HOME="${DIR}/../gembundle"
export GEM_PATH="${DIR}/../gembundle"
export RUBYLIB=$( "${DIR}/ruby2.4" -e "puts $:.join(':').gsub('././', ENV['VAGRANT_USR_DIR'])")
if [ "${SSL_CERT_FILE}" = "" ]; then
    export SSL_CERT_FILE="${DIR}/../../etc/ssl/ca-certificates.crt"
fi
if [ "${CURL_CA_BUNDLE}" = "" ]; then
    export CURL_CA_BUNDLE="${DIR}/../../etc/ssl/ca-certificates.crt"
fi

new_pkg_config_path="${DIR}/usr/lib/x86_64-linux-gnu/pkgconfig"

if [ "${PKG_CONFIG_PATH}" != "" ]; then
    new_pkg_config_path="${new_pkg_config_path}:${PKG_CONFIG_PATH}"
fi

if [ -x "$(command -v pkg-config)" ]; then
    new_pkg_config_path="${new_pkg_config_path}:$(pkg-config --variable pc_path pkg-config)"
fi

export PKG_CONFIG_PATH="${new_pkg_config_path}"
export VAGRANT_INSTALLER_ENV="1"
export VAGRANT_APPIMAGE="1"
export VAGRANT_INSTALLER_EMBEDDED_DIR="${DIR}/../.."
export NOKOGIRI_USE_SYSTEM_LIBRARIES="1"

if [ "${VAGRANT_PREFER_SYSTEM_BIN}" != "" -a "${VAGRANT_PREFER_SYSTEM_BIN}" != "0" ]; then
    export PATH="${PATH}:${DIR}"
else
    export PATH="${DIR}:${PATH}"
fi

new_ld_library_path="${DIR}/lib/x86_64-linux-gnu:${DIR}/usr/lib/x86_64-linux-gnu"

if [ -x "$(command -v ldconfig)" ]; then
    extra_ld_path=$(ldconfig -N -X -v 2>&1 | grep "^/.*:$" | tr -d ":" | tr "\n" ":")
else
    extra_ld_path="/lib:/lib64:/usr/lib:/usr/lib64"
fi

if [ "${extra_ld_path}" != "" ]; then
    new_ld_library_path="${new_ld_library_path}:${extra_ld_path}"
fi

if [ "${LD_LIBRARY_PATH}" != "" ]; then
    new_ld_library_path="${new_ld_library_path}:${LD_LIBRARY_PATH}"
fi

export VAGRANT_APPIMAGE_LD_LIBRARY_PATH="${new_ld_library_path}"

"${DIR}/ruby2.4" -- "${DIR}/../gembundle/bin/vagrant" "$@"
