#!/bin/bash
# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"

export PATH="/usr/local/bin:$PATH"

chmod 755 /vagrant/package/package.sh

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_darwin_x86_64.zip master

mkdir -p /vagrant/pkg
cp *.dmg /vagrant/pkg
