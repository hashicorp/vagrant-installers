#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


# This file contains version information for all dependencies
# required by the Vagrant substrates. Substrates are built
# and cached based on the git commit id. This allows substrates
# to be reused until a new version requires an updated substrate
# to be created. Some substrates (like windows) are built using
# a package manager and have more updates applied outside our
# view. Update the date below to force a new substrate build
# when no libraries need to be updated:

curl_version="8.10.1"
libarchive_version="3.7.2"
libffi_version="3.4.6"
libgcrypt_version="1.10.3"
libgmp_version="6.3.0"
libgpg_error_version="1.48"
libiconv_version="1.17"
libidn2_version="2.3.7"
libpsl_version="0.21.5"
# Need up update gcc version to use libssh2 1.9.0+
libssh2_version="1.11.0"
libunistring_version="1.2"
libxml2_version="2.12.6"
libxslt_version="1.1.39"
libyaml_version="0.2.5"
openssl_version="3.1.5"
readline_version="8.2"
ruby_version="3.3.6"
xz_version="5.4.0"
zlib_version="1.3.1"

# Only used for centos
libxcrypt_version="4.4.18"

# Only used for macOS
# NOTE: The 10.12 SDK was the earliest version of the
#       SDK which could properly build all the dependencies
# NOTE: Old SDK does not appear to work on arm, disable for now
#macos_sdk_file="MacOSX10.12.sdk.tgz"
#macos_deployment_target="10.12"
