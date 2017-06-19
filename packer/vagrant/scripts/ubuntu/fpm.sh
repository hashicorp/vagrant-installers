#!/bin/sh

apt-get install -yq build-essential ruby ruby-dev rubygems1.8 zip unzip
gem install json -v '~> 1.8.6' --no-ri --no-rdoc
gem install fpm -v '~> 0.4.0' --no-ri --no-rdoc
