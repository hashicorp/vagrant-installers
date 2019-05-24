#!/bin/sh

yum install -y nc zip unzip chrpath

sudo yum install -y centos-release-scl
sudo yum install -y  devtoolset-8-toolchain
source /opt/rh/devtoolset-8/enable

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"
mkdir -p /vagrant/substrate-assets
chmod 755 /vagrant/package/package.sh

set -e

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_centos_$(uname -m).zip master
pkg_dir=${VAGRANT_PACKAGE_OUTPUT_DIR:-"pkg"}
mkdir -p /vagrant/${pkg_dir}
cp *.rpm /vagrant/${pkg_dir}/
