#!/bin/bash
#
# This script will actually run the puppet code here.
TMP_CONFIG_DIR=/tmp/puppet_config

# We need to create a temporary configuration directory because Puppet
# needs to be able to set the permissions on this and if we call this
# from a filesystem that doesn't support that (VMWare shared folders),
# then Puppet will fail.
sudo rm -rf ${TMP_CONFIG_DIR}
sudo mkdir -p ${TMP_CONFIG_DIR}
sudo cp -R config/* ${TMP_CONFIG_DIR}

# On Mac OS X, we need to create the "puppet" group, otherwise Puppet
# will not run.
if [ `uname` = 'Darwin' ]; then
  sudo dscl . -create /groups/puppet
  sudo dscl . -create /groups/puppet gid 1000
  sudo dscl . -create /groups/puppet passwd '*'
fi

# Invoke Puppet
sudo puppet apply \
  --confdir=${TMP_CONFIG_DIR} \
  --modulepath=modules \
  manifests/init.pp
