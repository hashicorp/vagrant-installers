#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

export VAGRANT_BIN_DIR="${DIR}"
export VAGRANT_USR_DIR="${DIR}/../"
export GEM_HOME="$DIR/../gembundle"
export GEM_PATH="$DIR/../gembundle"
export RUBYLIB=$( "${DIR}/ruby2.4" -e "puts $:.join(':').gsub('././', ENV['VAGRANT_USR_DIR'])")
export SSL_CERT_FILE="$DIR/../../etc/ssl/ca-certificates.crt"
export CURL_CA_BUNDLE="$DIR/../../etc/ssl/ca-certificates.crt"
export LDFLAGS="-L$DIR/../lib/x86_64-linux-gnu -L$DIR/../../lib/x86_64-linux-gnu"
export CFLAGS="-I$DIR/../include"
export CPPFLAGS="-I$DIR/../include"
export VAGRANT_INSTALLER_ENV="1"
export VAGRANT_INSTALLER_EMBEDDED_DIR="${DIR}/../.."
export PATH="$DIR:$PATH"

"$DIR/ruby2.4" -- "$DIR/../gembundle/bin/vagrant" "$@"
