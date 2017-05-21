#!/bin/sh

relver=$(awk '{print $3}' /etc/redhat-release)

# use vault to access old packages
sed -i 's/mirror.centos.org\/centos/vault.centos.org/g' /etc/yum.repos.d/CentOS-Base.repo
sed -i "s/\$releasever/${relver}/g" /etc/yum.repos.d/CentOS-Base.repo
sed -i 's/#baseurl/baseurl/g' /etc/yum.repos.d/CentOS-Base.repo
sed -i 's/mirrorlist=.*$//g' /etc/yum.repos.d/CentOS-Base.repo

mkdir -p /etc/yum/vars/
echo $(awk '{print $3}' /etc/redhat-release) > /etc/yum/vars/releasever

yum install -y nc curl

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"

REPO_RPM_URL="http://yum.puppetlabs.com/puppetlabs-release-el-5.noarch.rpm"
rm -f /tmp/puppet.rpm
curl -o /tmp/puppet.rpm -L $REPO_RPM_URL
rpm -i /tmp/puppet.rpm
yum install -y puppet

mkdir -p /vagrant/substrate-assets
chmod 755 /vagrant/substrate/run.sh

/vagrant/substrate/run.sh /vagrant/substrate-assets
