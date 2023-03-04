#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


yum groupinstall -yq "development tools"
yum install -yq perl make kernel-headers kernel-devel wget curl  \
  rsync openssl-devel readline-devel zlib-devel net-tools nfs-utils

sudo yum install -y devtoolset-8-toolchain rh-perl524 rh-perl524-perl-open unzip git zip autoconf

yum -d 0 -e 0 -y install chrpath gcc make  rh-perl524-perl-Thread-Queue
yum -d 0 -e 0 -y install rh-perl524-perl-Data-Dumper python-devel
# Remove openssl dev files to prevent any conflicts when building
yum -d 0 -e 0 -y remove openssl-devel

echo '. /opt/rh/devtoolset-8/enable' >> /etc/profile
echo '. /opt/rh/rh-perl524/enable' >> /etc/profile
