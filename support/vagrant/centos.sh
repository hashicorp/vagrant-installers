#!/bin/env bash

# Update the yum repos
yum -y update

# Install git
yum -y groupinstall "Development Tools"
yum -y install git

# Ruby
yum -y install zlib-devel openssl-devel
pushd /tmp
wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p0.tar.gz
tar -zxvf ruby-1.9.3-p0.tar.gz
cd ruby-1.9.3-p0
./configure --disable-install-doc
make
make install
popd

# Rubygems
pushd /tmp
wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.15.tgz
tar -xvzf rubygems-1.8.15.tgz
cd rubygems-1.8.15
ruby setup.rb
popd

# Gems required
gem install chef --no-ri --no-rdoc
gem install rake --no-ri --no-rdoc

# Clone out the installers repo
git clone git://github.com/mitchellh/vagrant-installers.git
cd vagrant-installers
