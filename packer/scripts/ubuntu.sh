#!/bin/bash

# Install Puppet
wget --no-check-certificate \
    -O - \
    https://raw.github.com/hashicorp/puppet-bootstrap/master/ubuntu.sh \
    | sh -s

# Install Git
apt-get install -y git-core

# Install build-essential stuff we'll need
apt-get install -y build-essential
