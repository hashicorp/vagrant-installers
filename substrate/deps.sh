#!/usr/bin/env bash

# This file contains version information for all dependencies
# required by the Vagrant substrates. Substrates are built
# and cached based on the git commit id. This allows substrates
# to be reused until a new version requires an updated substrate
# to be created. Some substrates (like windows) are built using
# a package manager and have more updates applied outside our
# view. Update the date below to force a new substrate build
# when no libraries need to be updated:
#
# FORCE REBUILD: 2022-08-11 16:52:43-07:00

curl_version="7.87.0"
libarchive_version="3.6.2"
libffi_version="3.4.4"
libgcrypt_version="1.10.1"
libgmp_version="6.2.1"
libgpg_error_version="1.46"
libiconv_version="1.17"
# Need up update gcc version to use libssh2 1.9.0+
libssh2_version="1.8.0"
libxml2_version="2.10.3"
libxslt_version="1.1.37"
libyaml_version="0.2.5"
openssl_version="1.1.1s"
readline_version="8.2"
ruby_version="3.0.5"
xz_version="5.4.0"
zlib_version="1.2.13"

# Only used for centos
libxcrypt_version="4.4.18"
