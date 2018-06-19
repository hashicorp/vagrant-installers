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
export LDFLAGS="-L${DIR}/../lib/x86_64-linux-gnu -L${DIR}/../../lib/x86_64-linux-gnu ${LDFLAGS}"
export CFLAGS="-I${DIR}/../include ${CFLAGS}"
export CPPFLAGS="-I${DIR}/../include ${CPPFLAGS}"
export VAGRANT_INSTALLER_ENV="1"
export VAGRANT_APPIMAGE="1"
export VAGRANT_INSTALLER_EMBEDDED_DIR="${DIR}/../.."
export NOKOGIRI_USE_SYSTEM_LIBRARIES="1"

if [ "${VAGRANT_PREFER_SYSTEM_BIN}" != "" -a "${VAGRANT_PREFER_SYSTEM_BIN}" != "0" ]; then
    export PATH="${PATH}:${DIR}"
else
    export PATH="${DIR}:${PATH}"
fi

"${DIR}/ruby2.4" -- "${DIR}/../gembundle/bin/vagrant" "$@"
