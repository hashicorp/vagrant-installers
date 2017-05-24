#!/bin/sh

DEBIAN_FRONTEND=noninteractive apt-get update -yq
DEBIAN_FRONTEND=noninteractive apt-get install -yq ruby ruby1.8 libopenssl-ruby1.8 rubygems1.8
gem install json_pure -v '~> 1.0' --no-ri --no-rdoc
gem install puppet -v '~> 3.0' --no-ri --no-rdoc
ln -s /var/lib/gems/1.8/bin/puppet /usr/local/bin/puppet
