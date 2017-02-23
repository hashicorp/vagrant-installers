#!/bin/sh

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"

DEBIAN_FRONTEND=noninteractive apt-get update -yq
DEBIAN_FRONTEND=noninteractive apt-get update -yq
DEBIAN_FRONTEND=noninteractive apt-get install -yq build-essential ruby ruby-dev rubygems1.8 zip unzip
gem install json -v '~> 1.8.6' --no-ri --no-rdoc
gem install fpm -v '~> 0.4.0' --no-ri --no-rdoc
ln -s /var/lib/gems/1.8/bin/fpm /usr/local/bin/fpm
chmod 755 /vagrant/package/package.sh

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_ubuntu_$(uname -m).zip master
cp *.deb /vagrant/pkg/
