#!/bin/sh

mkdir "${HOME}/src"
pushd "${HOME}/src"

# Install OpenSSL
wget --no-check-certificate -O openssl.tar.gz https://www.openssl.org/source/openssl-1.0.2a.tar.gz

tar -zxf openssl.tar.gz
pushd openssl-*
./config -fpic shared && make && make install
echo "/usr/local/ssl/lib" >> /etc/ld.so.conf
ldconfig
popd

PKG_CONFIG_PATH=/usr/local/ssl/lib/pkgconfig; export PKG_CONFIG_PATH
LDFLAGS=`pkg-config --libs /usr/local/ssl/lib/pkgconfig/openssl.pc`; export LDFLAGS
CFLAGS=`pkg-config --cflags /usr/local/ssl/lib/pkgconfig/openssl.pc`; export CFLAGS

# Prefer /usr/local/bin
echo "export PATH=/usr/local/bin:$PATH" > /etc/profile.d/usr-local-path.sh
echo "export PATH=/usr/local/bin:$PATH" >> /home/vagrant/.bash_profile
chmod 755 /etc/profile.d/usr-local-path.sh

PATH=/usr/local/bin:$PATH; export PATH

# Install wget
wget --no-check-certificate -O wget.tar.gz https://ftp.gnu.org/gnu/wget/wget-1.19.1.tar.gz
tar -xzf wget.tar.gz
pushd wget-*
LDFLAGS=`pkg-config --libs /usr/local/ssl/lib/pkgconfig/openssl.pc` CFLAGS=`pkg-config --cflags /usr/local/ssl/lib/pkgconfig/openssl.pc` ./configure --with-ssl=openssl --with-openssl --with-libssl-prefix=/usr/local/ssl
make && make install
popd

# Install curl
/usr/local/bin/wget --no-check-certificate -O curl.tar.gz http://curl.haxx.se/download/curl-7.42.1.tar.gz
tar -xzf curl.tar.gz
pushd curl-*
./configure --with-ssl=/usr/local/ssl --disable-ldap && make && make install
popd

popd
