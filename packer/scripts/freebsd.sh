#! /usr/bin/env sh

set -e

pkg update
# For example, https://github.com/wunki/vagrant-freebsd, a very minimalistic
# FreeBSD image, has no wget/curl
pkg install -y wget
pkg install -y bash
# Ensure that /dev/fd is mounted (required by bash)
grep '/dev/fd\>' /etc/fstab > /dev/null || \
  echo 'fdesc   /dev/fd         fdescfs         rw      0       0' >> /etc/fstab
mount | grep '/dev/fd\>' > /dev/null || \
  mount /dev/fd

# Install Puppet
wget --no-check-certificate \
    -O - \
    https://raw.github.com/hashicorp/puppet-bootstrap/master/freebsd.sh \
    | bash -s

# Install Git
pkg install -y git
