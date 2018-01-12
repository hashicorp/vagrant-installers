#!/bin/sh

gem install puppet -v '~> 3.0' --no-document

# install missing gem dependency
gem install xmlrpc --no-document

# Puppet assumes Syck will be in use, but it is not. So kill
# the monkey patch so nothing is modified and puppet will
# load successfully
echo "" > /usr/lib/ruby/gems/2.4.0/gems/puppet-3.8.7/lib/puppet/vendor/safe_yaml/lib/safe_yaml/syck_node_monkeypatch.rb
