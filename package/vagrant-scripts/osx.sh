#!/bin/bash

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

set -x

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"

export PATH="/usr/local/bin:$PATH"

gem install json_pure -v '~> 1.0' --no-ri --no-rdoc
gem install puppet -v '~> 3.0' --no-ri --no-rdoc
gem install fpm -v '~> 0.4.0' --no-ri --no-rdoc
chmod 755 /vagrant/package/package.sh

TRAVIS=1 su vagrant -l -c 'ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
pushd /tmp
su vagrant -c "brew install python"
rm /usr/bin/python
ln -s /usr/local/bin/python /usr/bin/python
su vagrant -c "brew install /vagrant/package/vagrant-scripts/dmgbuild.rb"
popd

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_darwin_x86_64.zip master

mkdir -p /vagrant/pkg
cp *.dmg /vagrant/pkg
