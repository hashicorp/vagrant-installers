#!/bin/bash

# Install Puppet
wget --no-check-certificate \
    -O - \
    https://raw.github.com/hashicorp/puppet-bootstrap/master/ubuntu.sh \
    | sh -s

# Install Git
apt-get install -y git-core

# Install and update RubyGems
apt-get install -y rubygems
gem install --no-ri --no-rdoc rubygems-update
cd /var/lib/gems/1.8/bin
./update_rubygems

# Install build-essential stuff we'll need
apt-get install -y build-essential ruby-dev
