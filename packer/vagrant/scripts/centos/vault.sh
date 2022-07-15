#!/usr/bin/env bash

set -e

sed -i 's/$releasever/6.10/' /etc/yum.repos.d/CentOS-Base.repo
sed -i 's/\/centos//' /etc/yum.repos.d/CentOS-Base.repo
sed -i 's/mirror.centos/vault.centos/' /etc/yum.repos.d/CentOS-Base.repo
sed -i 's/^#baseurl/baseurl/' /etc/yum.repos.d/CentOS-Base.repo
sed -i 's/^mirrorlist/#mirrorlist/' /etc/yum.repos.d/CentOS-Base.repo

yum install -y centos-release-scl

sed -i 's/\/6/\/6.10/' /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
sed -i 's/\/centos//' /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
sed -i 's/mirror.centos/vault.centos/' /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
sed -i 's/buildlogs.centos/vault.centos/' /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
sed -i 's/debuginfo.centos/vault.centos/' /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
sed -i 's/^# *baseurl/baseurl/' /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
sed -i 's/^mirrorlist/#mirrorlist/' /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo

sed -i 's/\/6/\/6.10/' /etc/yum.repos.d/CentOS-SCLo-scl.repo
sed -i 's/\/centos//' /etc/yum.repos.d/CentOS-SCLo-scl.repo
sed -i 's/mirror.centos/vault.centos/' /etc/yum.repos.d/CentOS-SCLo-scl.repo
sed -i 's/buildlogs.centos/vault.centos/' /etc/yum.repos.d/CentOS-SCLo-scl.repo
sed -i 's/debuginfo.centos/vault.centos/' /etc/yum.repos.d/CentOS-SCLo-scl.repo
sed -i 's/^# *baseurl/baseurl/' /etc/yum.repos.d/CentOS-SCLo-scl.repo
sed -i 's/^mirrorlist/#mirrorlist/' /etc/yum.repos.d/CentOS-SCLo-scl.repo
