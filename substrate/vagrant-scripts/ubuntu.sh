#!/bin/sh

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"

DEBIAN_FRONTEND=noninteractive apt-get update -yq
DEBIAN_FRONTEND=noninteractive apt-get install -yq ruby libopenssl-ruby rubygems1.8
gem install json_pure -v '~> 1.0' --no-ri --no-rdoc
gem install puppet -v '~> 3.0' --no-ri --no-rdoc
ln -s /var/lib/gems/1.8/bin/puppet /usr/local/bin/puppet
mkdir -p /vagrant/substrate-assets
chmod 755 /vagrant/substrate/run.sh

/vagrant/substrate/run.sh /vagrant/substrate-assets
