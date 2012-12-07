#!/bin/bash
#
# This script will actually run the puppet code here.
TMP_CONFIG_DIR=/tmp/puppet_config

# Verify arguments
if [ "$#" -ne "3" ]; then
  echo "Usage: $0 revision version output_directory" >&2
  exit 1
fi

# We need to create a temporary configuration directory because Puppet
# needs to be able to set the permissions on this and if we call this
# from a filesystem that doesn't support that (VMWare shared folders),
# then Puppet will fail.
sudo rm -rf ${TMP_CONFIG_DIR}
sudo mkdir -p ${TMP_CONFIG_DIR}
sudo cp -R config/* ${TMP_CONFIG_DIR}

# Export the parameters for Puppet
export FACTER_param_vagrant_revision="$1"
export FACTER_param_vagrant_version="$2"
export FACTER_param_dist_dir="$3"

# Invoke Puppet
sudo -E puppet apply \
  --confdir=${TMP_CONFIG_DIR} \
  --modulepath=modules \
  manifests/init.pp
