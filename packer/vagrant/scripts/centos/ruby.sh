#!/usr/bin/bash

pushd /tmp

# system update
yum -y install libxslt-devel libyaml-devel libxml2-devel gdbm-devel libffi-devel zlib-devel openssl-devel libyaml-devel readline-devel curl-devel openssl-devel pcre-devel git

version=2.4.3
cd /usr/local/src
wget https://cache.ruby-lang.org/pub/ruby/2.4/ruby-$version.tar.gz
tar zxvf ruby-$version.tar.gz
cd ruby-$version
./configure --prefix=/usr
make
make install
