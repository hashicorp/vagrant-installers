#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Determine where the CA certificate bundle is located. If
# a custom value is provided, use that for the default. Otherwise
# test known location for the file. If none is found, alert
# the user and carry on.
if [ -n "${SSL_CERT_FILE}" ]; then
    if [ -f "${SSL_CERT_FILE}" ]; then
        default_ssl_cert_file="${SSL_CERT_FILE}"
    else
        unset SSL_CERT_FILE
    fi
fi

if [ -n "${CURL_CA_BUNDLE}" ]; then
    if [ -f "${CURL_CA_BUNDLE}" ]; then
        if [ -z "${default_ssl_cert_file}" ]; then
            default_ssl_cert_file="${CURL_CA_BUNDLE}"
        fi
    else
        unset CURL_CA_BUNDLE
    fi
fi

if [ -z "${default_ssl_cert_file}" ]; then
    if [ -f "/etc/ssl/certs/ca-certificates.crt" ]; then
        default_ssl_cert_file="/etc/ssl/certs/ca-certificates.crt"
    elif [ -f "/etc/ssl/ca-certificates.crt" ]; then
        default_ssl_cert_file="/etc/ssl/ca-certificates.crt"
    elif [ -f "/etc/ca-certificates.crt" ]; then
        default_ssl_cert_file="/etc/ca-certificates.crt"
    elif [ -f "/etc/pki/tls/certs/ca-bundle.crt" ]; then
        default_ssl_cert_file="/etc/pki/tls/certs/ca-bundle.crt"
    elif [ -f "/etc/ssl/ca-bundle.pem" ]; then
        default_ssl_cert_file="/etc/ssl/ca-bundle.pem"
    elif [ -f "/etc/pki/tls/cacert.pem" ]; then
        default_ssl_cert_file="/etc/pki/tls/cacert.pem"
    elif [ -f "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem" ]; then
        default_ssl_cert_file="/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
    elif [ -f "/etc/ssl/cert.pem" ]; then
        default_ssl_cert_file="/etc/ssl/cert.pem"
    else
        echo "WARNING: Failed to locate ca-certificates.crt file!"
        echo
        echo   "Please locate the ca-certificates.crt file and set"
        echo   "it to the SSL_CERT_FILE and CURL_CA_BUNDLE environment"
        echo   "variables to ensure valid SSL behavior."
    fi
fi

unset RUBYLIB
unset RUBYOPT
export VAGRANT_BIN_DIR="${DIR}"
export VAGRANT_USR_DIR="$( cd -P "$( dirname "$VAGRANT_BIN_DIR" )" && pwd )"
export VAGRANT_ROOT_DIR="$( cd -P "$( dirname "$VAGRANT_USR_DIR" )" && pwd )"
export GEM_HOME="${VAGRANT_ROOT_DIR}/gems"
export GEM_PATH="${VAGRANT_ROOT_DIR}/gems"

# Set our SSL certificate locations unless they are already set
if [ -z "${SSL_CERT_FILE}" ]; then
    export SSL_CERT_FILE="${default_ssl_cert_file}"
fi

if [ -z "${CURL_CA_BUNDLE}" ]; then
    export CURL_CA_BUNDLE="${default_ssl_cert_file}"
fi

new_pkg_config_path="${VAGRANT_ROOT_DIR}/usr/lib/x86_64-linux-gnu/pkgconfig-int"

if [ -z "${PKG_CONFIG_PATH}" ]; then
    new_pkg_config_path="${new_pkg_config_path}:${PKG_CONFIG_PATH}"
fi

if [ -x "$(command -v pkg-config)" ]; then
    new_pkg_config_path="${new_pkg_config_path}:$(pkg-config --variable pc_path pkg-config)"
fi

export PKG_CONFIG_PATH="${new_pkg_config_path}"
export VAGRANT_INSTALLER_ENV="1"
export VAGRANT_APPIMAGE="1"
export VAGRANT_INSTALLER_EMBEDDED_DIR="${VAGRANT_ROOT_DIR}"

# Don't set this by default. Allow users to decide if system libraries should be used.
# export NOKOGIRI_USE_SYSTEM_LIBRARIES="1"

# Set these for easier debugging so they show up in the logs
export VAGRANT_PKG_CONFIG_PATH="${PKG_CONFIG_PATH}"
export VAGRANT_RUBYLIB="${RUBYLIB}"

if [[ "${VAGRANT_PREFER_SYSTEM_BIN}" != "" && "${VAGRANT_PREFER_SYSTEM_BIN}" != "0" ]]; then
    export PATH="${PATH}:${DIR}"
else
    export PATH="${DIR}:${PATH}"
fi

# Do some library path modifications to make things play nice. This
# is mainly for executing external commands so dynamic links aren't
# resolved to libraries within the AppImage by default.
original_ld_library_path="${LD_LIBRARY_PATH}"
unset LD_LIBRARY_PATH

# Attempt to find the linker path
lds=("/lib64/ld-linux-"*)
ld="${lds[0]}"

# Variable to store extra paths
extra_ld_path=""

# Check if the linker was found
if [ -x "${ld}" ]; then
    # Enable globbing extension if available
    if shopt -s extglob; then
        # Grab help information which will include search directories
        if ld_info="$("${ld}" --help 2>&1)"; then
            # Extract the library paths
            while IFS= read -rd $'\n' line; do
                if [[ "${line}" = *" /"*"("* ]]; then
                    line="${line#*/}"
                    line="/${line% (*}"
                    extra_ld_path+=":${line}"
                fi
            done <<< "${ld_info}"
            # Remove prefixed : character
            extra_ld_path="${line:1}"
        fi
    fi
fi

# If no library paths were found, just use a default list
if [ -z "${extra_ld_path}" ]; then
    extra_ld_path="/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib:/usr/lib:/lib64:/usr/lib64"
fi

# Set custom variables to be used for swapping paths when
# calling executables from vagrant.
export VAGRANT_APPIMAGE_HOST_LD_LIBRARY_PATH="${extra_ld_path}:${original_ld_library_path}"
export VAGRANT_APPIMAGE_LD_LIBRARY_PATH="${original_ld_library_path}:${extra_ld_path}"

# Reset the variable
export LD_LIBRARY_PATH="${original_ld_library_path}"

# Python variables will be set but we don't want them
unset PYTHONHOME
unset PYTHONPATH

# Before we get started, check that curl and SSH are available
if [ ! -x "$(command -v curl)" ]; then
    echo "WARNING: Failed to locate 'curl' executable"
    echo "  Vagrant relies on 'curl' for handling assets. Please"
    echo "  ensure that 'curl' has been installed to prevent errors"
    echo "  when Vagrant is uploading or downloading assets."
    echo
fi

if [ ! -x "$(command -v ssh)" ]; then
    echo "WARNING: Failed to locate 'ssh' executable"
    echo "  Vagrant relies on the 'ssh' command for connecting to"
    echo "  guests. Please ensure that 'ssh' has been installed to"
    echo "  prevent error when Vagrant attempts to connect to guests."
fi

"${VAGRANT_USR_DIR}/bin/ruby" -- "${GEM_PATH}/bin/vagrant" "$@"
