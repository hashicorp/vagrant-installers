#!/usr/bin/env bash
#
# This script will setup the dependencies for the installer generator
# and will actually finish by running the installer generator. The result
# is that a package should appear in the `dist` directory.

# Update the source list
apt-get update

# Install git
apt-get install -y git-core

# Install ruby
apt-get install -y build-essential ruby ruby-dev libopenssl-ruby1.8 irb ri rdoc

# Install RubyGems
pushd /tmp
wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz
tar xvzf rubygems-1.3.7.tgz
cd rubygems-1.3.7
ruby setup.rb
ln -s /usr/bin/gem1.8 /usr/bin/gem
popd
rm -rf /tmp/*

# Install Chef
gem install chef --no-ri --no-rdoc

# Install Rake
gem install rake --no-ri --no-rdoc

# Run the installer generate
cd /vagrant
rake
