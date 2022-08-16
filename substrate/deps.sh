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

autoconf_version="2.71"
curl_version="7.84.0"
libarchive_version="3.6.1"
libffi_version="3.4.2"
libgcrypt_version="1.10.1"
libgmp_version="6.2.1"
libgpg_error_version="1.45"
libiconv_version="1.17"
# Need up update gcc version to use libssh2 1.9.0+
libssh2_version="1.8.0"
libxml2_version="2.9.14"
libxslt_version="1.1.35"
libyaml_version="0.2.5"
openssl_version="1.1.1q"
readline_version="8.1.2"
ruby_version="2.7.6"
xz_version="5.2.5"
zlib_version="1.2.12"

# Used for centos builds
m4_version="1.4.18"
automake_version="1.16.3"
libtool_version="2.4.6"
patchelf_version="0.9"
libxcrypt_version="4.4.18"
