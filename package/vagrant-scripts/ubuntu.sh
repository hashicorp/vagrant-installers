#!/bin/sh

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"

chmod 755 /vagrant/package/package.sh
apt-get update -yq
apt-get install -yq build-essential chrpath

# Ensure we can get to fpm
export PATH=$PATH:/var/lib/gems/1.8/bin

set -e

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_ubuntu_$(uname -m).zip master
mkdir -p /vagrant/pkg
cp *.deb /vagrant/pkg/
