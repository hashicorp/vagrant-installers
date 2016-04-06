#! /usr/bin/env bash
#
# This script will actually run the puppet code here.

# Verify we're running as root
if [ "$EUID" -ne "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

# Verify arguments
if [ "$#" -ne "1" ]; then
  echo "Usage: $0 output-dir" >&2
  exit 1
fi

# Find the directory of this script
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Find the puppet version
PUPPET_VERSION=$(puppet --version)

# We need to create a temporary configuration directory because Puppet
# needs to be able to set the permissions on this and if we call this
# from a filesystem that doesn't support that (VMWare shared folders),
# then Puppet will fail.
TMP_CONFIG_DIR=$(mktemp -d -t vagrant-installer.XXXXXX)
cp -R ${DIR}/config/* ${TMP_CONFIG_DIR}

# Setup the output directory
mkdir -p $1

# Export the parameters for Puppet
export FACTER_param_homebrew_user=${SUDO_USER}
export FACTER_param_output_dir=$(cd $1; pwd)

# Invoke Puppet
cd $DIR
case "$PUPPET_VERSION" in
  [4-9].*)
    puppet apply \
      --codedir=${TMP_CONFIG_DIR} \
      --confdir=${TMP_CONFIG_DIR} \
      --modulepath=${DIR}/modules \
      ${DIR}/manifests/init.pp ;;
  *)
    puppet apply \
      --confdir=${TMP_CONFIG_DIR} \
      --modulepath=${DIR}/modules \
      ${DIR}/manifests/init.pp ;;
esac
