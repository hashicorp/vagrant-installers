#!/usr/bin/env bash
#
# NOTE: THIS SCRIPT SHOULD NOT BE CALLED DIRECTLY. CALL THE ROOT
# "build.sh" instead.
#
# This is a wrapper that is able to install a version of Vagrant into
# the substrate. Once this command runs, the substrate directory it is
# pointed to is no longer valid.
set -e
set -x

# Verify arguments
if [ "$#" -ne "3" ]; then
  echo "Usage: $0 SUBSTRATE-DIR VAGRANT-REVISION VERSION-FILE" >&2
  exit 1
fi

SUBSTRATE_DIR=$1
EMBEDDED_DIR="$1/embedded"
VAGRANT_REV=$2
VERSION_OUTPUT=$3

GEM_COMMAND="${EMBEDDED_DIR}/bin/gem"

# Work in a temporary directory
TMP_DIR=$(mktemp -d tmp.XXXXXXXXX)
pushd $TMP_DIR

# Download Vagrant and extract
SOURCE_REPO=${VAGRANT_REPO:-mitchellh/vagrant}
SOURCE_PREFIX=${SOURCE_REPO/\//-}
SOURCE_URL="https://api.github.com/repos/${SOURCE_REPO}/tarball/${VAGRANT_REV}"
if [ -z "${VAGRANT_TOKEN}" ]; then
    curl -L ${SOURCE_URL} > vagrant.tar.gz
else
    curl -L -u "${VAGRANT_TOKEN}:x-oauth-basic" ${SOURCE_URL} > vagrant.tar.gz
fi
rm -rf ${SOURCE_PREFIX}-*
tar xvzf vagrant.tar.gz
rm vagrant.tar.gz
cd ${SOURCE_PREFIX}-*

# If we have a version file, use that. Otherwise, use a timestamp
# on version 0.1.
if [ ! -f "version.txt" ]; then
    echo -n "0.1.0" > version.txt
fi
VERSION=$(cat version.txt | sed -e 's/\.[^0-9]*$//')
echo -n $VERSION >${VERSION_OUTPUT}

# Build the gem
${GEM_COMMAND} build vagrant.gemspec
cp vagrant-*.gem vagrant.gem

# We want to use the system libxml/libxslt for Nokogiri
export NOKOGIRI_USE_SYSTEM_LIBRARIES=1

# Install the gem. Export all these environmental variables so the Gem
# goes into the proper place.
export GEM_PATH="${EMBEDDED_DIR}/gems"
export GEM_HOME="${GEM_PATH}"
export GEMRC="${EMBEDDED_DIR}/etc/gemrc"
export CPPFLAGS="-I${EMBEDDED_DIR}/include -I${EMBEDDED_DIR}/include/libxml2"
export CFLAGS="${CPPFLAGS}"
export LDFLAGS="-L${EMBEDDED_DIR}/lib"
export PATH="${EMBEDDED_DIR}/bin:${PATH}"
export SSL_CERT_FILE="${EMBEDDED_DIR}/cacert.pem"

# Darwin
if [[ "$OSTYPE" == "darwin"* ]]; then
    export CONFIGURE_ARGS="-Wl,-rpath,${EMBEDDED_DIR}/lib"
fi

${GEM_COMMAND} install vagrant.gem --no-document

# Install extensions
${GEM_COMMAND} install vagrant-share --no-document --conservative --clear-sources --source "https://gems.hashicorp.com"

# Setup the system plugins
cat <<EOF >${EMBEDDED_DIR}/plugins.json
{
    "version": "1",
    "installed": {
        "vagrant-share": {
            "ruby_version": "0",
            "vagrant_version": "${VERSION}"
        }
    }
}
EOF
chmod 0644 ${EMBEDDED_DIR}/plugins.json

# Exit the temporary directory
popd
rm -rf ${TMP_DIR}
