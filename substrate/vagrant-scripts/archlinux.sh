#!/bin/sh

export PATH=/root/.gem/ruby/2.2.0/bin:$PATH

mkdir -p /vagrant/substrate-assets
chmod 755 /vagrant/substrate/run.sh

/vagrant/substrate/run.sh /vagrant/substrate-assets
