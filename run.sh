#!/usr/bin/env bash
#
# This script will actually run the puppet code here.

# Verify we're running as root
if [ "$EUID" -ne "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

# Verify arguments
if [ "$#" -ne "3" ]; then
  echo "Usage: $0 revision version output_directory" >&2
  exit 1
fi

# Find the directory of this script
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# We need to create a temporary configuration directory because Puppet
# needs to be able to set the permissions on this and if we call this
# from a filesystem that doesn't support that (VMWare shared folders),
# then Puppet will fail.
TMP_CONFIG_DIR=$(mktemp -d -t vagrant-installer.XXXXXX)
cp -R ${DIR}/config/* ${TMP_CONFIG_DIR}

# Export the parameters for Puppet
export FACTER_param_vagrant_revision="$1"
export FACTER_param_vagrant_version="$2"
export FACTER_param_dist_dir="$3"

# Invoke Puppet
cd $DIR
puppet apply \
  --confdir=${TMP_CONFIG_DIR} \
  --modulepath=${DIR}/modules \
  ${DIR}/manifests/init.pp
