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

# curl (.tar.gz) - https://curl.se/download.html
curl_version="8.10.1"
curl_shasum="d15ebab765d793e2e96db090f0e172d127859d78ca6f6391d7eafecfd894bbc0"

# libarchive (.tar.gz) - https://github.com/libarchive/libarchive/releases
libarchive_version="3.7.8"
libarchive_shasum="a123d87b1bd8adb19e8c187da17ae2d957c7f9596e741b929e6b9ceefea5ad0f"

# libffi (.tar.gz) - https://github.com/libffi/libffi/releases
libffi_version="3.4.7"
libffi_shasum="138607dee268bdecf374adf9144c00e839e38541f75f24a1fcf18b78fda48b2d"

# libgcrypt (.tar.bz2) - https://gnupg.org/download/index.html
libgcrypt_version="1.11.0"
libgcrypt_shasum="09120c9867ce7f2081d6aaa1775386b98c2f2f246135761aae47d81f58685b9c"

# libgpg-error (.tar.bz2) - https://gnupg.org/download/index.html
libgpg_error_version="1.51"
libgpg_error_shasum="be0f1b2db6b93eed55369cdf79f19f72750c8c7c39fc20b577e724545427e6b2"

# libgmp (.tar.bz2) - https://gmplib.org/download/gmp/
libgmp_version="6.3.0"
libgmp_shasum="ac28211a7cfb609bae2e2c8d6058d66c8fe96434f740cf6fe2e47b000d1c20cb"

# libiconv (.tar.gz) - https://ftp.gnu.org/pub/gnu/libiconv/
libiconv_version="1.18"
libiconv_shasum="3b08f5f4f9b4eb82f151a7040bfd6fe6c6fb922efe4b1659c66ea933276965e8"

# libidn2 (.tar.gz) - https://ftp.gnu.org/gnu/libidn/
libidn2_version="2.3.8"
libidn2_shasum="f557911bf6171621e1f72ff35f5b1825bb35b52ed45325dcdee931e5d3c0787a"

# libpsl (.tar.gz) - https://github.com/rockdaboot/libpsl/releases
libpsl_version="0.21.5"
libpsl_shasum="1dcc9ceae8b128f3c0b3f654decd0e1e891afc6ff81098f227ef260449dae208"

# libssh2 (.tar.gz) - https://libssh2.org/download/
libssh2_version="1.11.1"
libssh2_shasum="d9ec76cbe34db98eec3539fe2c899d26b0c837cb3eb466a56b0f109cabf658f7"

# libunistring (.tar.gz) - https://ftp.gnu.org/gnu/libunistring/
libunistring_version="1.3"
libunistring_shasum="8ea8ccf86c09dd801c8cac19878e804e54f707cf69884371130d20bde68386b7"

# libxml2 (.tar.xz) - https://download.gnome.org/sources/libxml2/2.12/
libxml2_version="2.12.10"
libxml2_shasum="c3d8c0c34aa39098f66576fe51969db12a5100b956233dc56506f7a8679be995"

# libxslt (.tar.xz) - https://download.gnome.org/sources/libxslt/1.1/
libxslt_version="1.1.39"
libxslt_shasum="2a20ad621148339b0759c4d4e96719362dee64c9a096dbba625ba053846349f0"

# libyaml (.tar.gz) - https://github.com/yaml/libyaml/releases
libyaml_version="0.2.5"
libyaml_shasum="c642ae9b75fee120b2d96c712538bd2cf283228d2337df2cf2988e3c02678ef4"

# openssl (.tar.gz) - https://openssl-library.org/source/
openssl_version="3.1.8"
openssl_shasum="d319da6aecde3aa6f426b44bbf997406d95275c5c59ab6f6ef53caaa079f456f"

# readline (.tar.gz) - https://ftp.gnu.org/gnu/readline/
readline_version="8.2"
readline_shasum="3feb7171f16a84ee82ca18a36d7b9be109a52c04f492a053331d7d1095007c35"

# ruby (.zip) - https://cache.ruby-lang.org/pub/ruby/
ruby_version="3.3.7"
ruby_shasum="9c6b1d13a03d8423391e070e324b1380a597d3ac9eb5d8ea40bc4fd5226556a5"

# xz (.tar.gz) - https://tukaani.org/xz/#_stable
xz_version="5.6.4"
xz_shasum="269e3f2e512cbd3314849982014dc199a7b2148cf5c91cedc6db629acdf5e09b"

# zlib (.tar.gz) - https://zlib.net/
zlib_version="1.3.1"
zlib_shasum="9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23"

# libxcrypt (.tar.xz) - https://github.com/besser82/libxcrypt/releases
libxcrypt_version="4.4.38"
libxcrypt_shasum="80304b9c306ea799327f01d9a7549bdb28317789182631f1b54f4511b4206dd6"

# cacert (.pem) - https://curl.se/docs/sslcerts.html
cacert_version="2025-02-25"
cacert_shasum="50a6277ec69113f00c5fd45f09e8b97a4b3e32daa35d3a95ab30137a55386cef"

# Only used for macOS
# NOTE: The 10.12 SDK was the earliest version of the
#       SDK which could properly build all the dependencies
# NOTE: Old SDK does not appear to work on arm, disable for now
#macos_sdk_file="MacOSX10.12.sdk.tgz"
#macos_deployment_target="10.12"
