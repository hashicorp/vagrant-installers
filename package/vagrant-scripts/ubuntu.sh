#!/bin/sh

# Force a DNS update
echo "dns-nameservers 8.8.8.8" >> /etc/network/interfaces
service network-interface restart INTERFACE=eth0

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"

chmod 755 /vagrant/package/package.sh
apt-get update -yq
apt-get update -yq

apt-get install -yq build-essential chrpath

# Ensure we can get to fpm
export PATH=$PATH:/var/lib/gems/1.8/bin

set -e

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_ubuntu_$(uname -m).zip main

pkg_dir=${VAGRANT_PACKAGE_OUTPUT_DIR:-"pkg"}
mkdir -p /vagrant/${pkg_dir}
cp *.deb /vagrant/${pkg_dir}/
