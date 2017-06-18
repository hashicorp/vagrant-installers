#!/bin/sh

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"

chmod 755 /vagrant/package/package.sh

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_ubuntu_$(uname -m).zip master
mkdir -p /vagrant/pkg
cp *.deb /vagrant/pkg/
