#!/usr/bin/env bash
#
# Builds the package for Vagrant unix-like systems (Mac OS X and Linux).
set -e

# Verify arguments
if [ "$#" -ne "2" ]; then
  echo "Usage: $0 SUBSTRATE-PATH VAGRANT-REVISION" >&2
  exit 1
fi

SUBSTRATE_PATH=$1
VAGRANT_REVISION=$2

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

#--------------------------------------------------------------------
# Common Operations
#--------------------------------------------------------------------
# Create a writeable temporary directory
TMP_DIR=$(mktemp -d tmp.XXXXXXXXXX)
TMP_DIR=$(cd ${TMP_DIR}; pwd)
export TMPDIR="${TMP_DIR}"

# Copy the substrate and unzip it
SUBSTRATE_TMP_DIR=$(mktemp -d tmp.XXXXXXXXXX)
cp $SUBSTRATE_PATH ${SUBSTRATE_TMP_DIR}/substrate.zip
pushd $SUBSTRATE_TMP_DIR
unzip substrate.zip
popd
rm -rf /opt/vagrant
mkdir -p /opt/vagrant
mv ${SUBSTRATE_TMP_DIR}/substrate/* /opt/vagrant/
SUBSTRATE_DIR="/opt/vagrant"

# Install Vagrant
"${DIR}/support/install_vagrant.sh" \
    ${SUBSTRATE_DIR} ${VAGRANT_REVISION} ${TMPDIR}/vagrant_version
VAGRANT_VERSION=$(cat ${TMPDIR}/vagrant_version)

#--------------------------------------------------------------------
# OS-specific packaging
#--------------------------------------------------------------------
# Debian
if [ -f "/etc/debian_version" ]; then
    ${DIR}/support/package_ubuntu.sh ${SUBSTRATE_DIR} ${VAGRANT_VERSION}
fi

# CentOS/RHEL/Fedora
if [ -f "/etc/redhat-release" ]; then
    ${DIR}/support/package_centos.sh ${SUBSTRATE_DIR} ${VAGRANT_VERSION}
fi

# Darwin
if [[ "$OSTYPE" == "darwin"* ]]; then
    "${DIR}/support/package_darwin.sh" ${SUBSTRATE_DIR} ${VAGRANT_VERSION}
fi

# Clean up the temporary dir
rm -rf ${SUBSTRATE_TMP_DIR} ${TMP_DIR}
