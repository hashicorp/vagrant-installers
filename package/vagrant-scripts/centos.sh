#!/bin/sh

yum install -y nc curl zip unzip

REPO_RPM_URL="http://yum.puppetlabs.com/puppetlabs-release-el-5.noarch.rpm"
rm -f /tmp/puppet.rpm
curl -o /tmp/puppet.rpm -L $REPO_RPM_URL
rpm -i /tmp/puppet.rpm
yum install -y puppet ruby-devel

yum groupinstall -yq "Development Tools"
gem install json -v '~> 1.8.6' --no-ri --no-rdoc
gem install fpm -v '~> 0.4.0' --no-ri --no-rdoc

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"
mkdir -p /vagrant/substrate-assets
chmod 755 /vagrant/package/package.sh

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_centos_$(uname -m).zip master
cp *.rpm /vagrant/pkg/
