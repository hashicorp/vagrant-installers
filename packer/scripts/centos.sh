#!/bin/bash

# Install Puppet
wget --no-check-certificate \
    -O - \
    https://raw.github.com/hashicorp/puppet-bootstrap/master/centos_5_x.sh \
    | sh -s

# Install EPEL so we can get Git, then get Git
rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
yum install -y git

# Install and update RubyGems
gem install --no-ri --no-rdoc rubygems-update
update_rubygems

# Install build-essential stuff we'll need
yum groupinstall -y "Development Tools"
yum install -y ruby-devel

# Install fpm
gem install fpm --no-ri --no-rdoc
