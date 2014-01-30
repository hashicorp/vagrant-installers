#!/usr/bin/env bash
#
# NOTE: THIS SCRIPT SHOULD NOT BE CALLED DIRECTLY. CALL THE ROOT
# "build.sh" instead.
#
# This is a wrapper that is able to install a version of Vagrant into
# the substrate. Once this command runs, the substrate directory it is
# pointed to is no longer valid.
set -e

# Verify arguments
if [ "$#" -ne "2" ]; then
  echo "Usage: $0 SUBSTRATE-DIR VAGRANT-REVISION" >&2
  exit 1
fi

SUBSTRATE_DIR=$1
EMBEDDED_DIR="$1/embedded"
VAGRANT_REV=$2

GEM_COMMAND="${EMBEDDED_DIR}/bin/gem"

# Work in a temporary directory
TMP_DIR=$(mktemp -d tmp.XXXXXXXXX)
pushd $TMP_DIR

# Download Vagrant and extract
SOURCE_URL="https://github.com/mitchellh/vagrant/archive/${VAGRANT_REV}.tar.gz"
wget --output-document=vagrant.tar.gz ${SOURCE_URL}
tar xvzf vagrant.tar.gz
rm vagrant.tar.gz
cd vagrant-${VAGRANT_REV}

# Build the gem
${GEM_COMMAND} build vagrant.gemspec
cp vagrant-*.gem vagrant.gem

# Install the gem. Export all these environmental variables so the Gem
# goes into the proper place.
export GEM_PATH="${EMBEDDED_DIR}/gems"
export GEM_HOME="${GEM_PATH}"
export GEMRC="${EMBEDDED_DIR}/etc/gemrc"
export CPPFLAGS="-I${EMBEDDED_DIR}/include"
export LDFLAGS="-L${EMBEDDED_DIR}/lib"
export PATH="${EMBEDDED_DIR}/bin:${PATH}"
${GEM_COMMAND} install vagrant.gem --no-ri --no-rdoc

# Exit the temporary directory
popd
rm -rf ${TMP_DIR}
