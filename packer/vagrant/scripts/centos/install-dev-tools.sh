#!/bin/sh

yum groupinstall -yq "development tools"
yum install -yq perl make kernel-headers kernel-devel wget curl  \
  rsync openssl-devel readline-devel zlib-devel net-tools nfs-utils
