#!/bin/sh

relver="5.11" #$(awk '{print $3}' /etc/redhat-release)

# use vault to access old packages
sed -i 's/mirror.centos.org\/centos/vault.centos.org/g' /etc/yum.repos.d/CentOS-Base.repo
sed -i "s/\$releasever/${relver}/g" /etc/yum.repos.d/CentOS-Base.repo
sed -i 's/#baseurl/baseurl/g' /etc/yum.repos.d/CentOS-Base.repo
sed -i 's/mirrorlist=.*$//g' /etc/yum.repos.d/CentOS-Base.repo
