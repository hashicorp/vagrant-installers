#!/usr/bin/env bash
#
# NOTE: THIS SCRIPT SHOULD NOT BE CALLED DIRECTLY. CALL THE ROOT
# "package.sh" instead.
#
# This is a wrapper that is able to install a version of Vagrant into
# the substrate. Once this command runs, the substrate directory it is
# pointed to is no longer valid.
set -e
set -x

function relpath() {
    path_to=`readlink -f "$2"`
    source=`readlink -f "$1"`
    rel=$(perl -MFile::Spec -e "print File::Spec->abs2rel(q($path_to),q($source))")
    echo $rel
}

# Verify arguments
if [ "$#" -ne "3" ]; then
  echo "Usage: $0 SUBSTRATE-DIR VAGRANT-REVISION VERSION-FILE" >&2
  exit 1
fi

SUBSTRATE_DIR=$1
EMBEDDED_DIR="$1/embedded"
VAGRANT_REV=$2
VERSION_OUTPUT=$3

export GEM_COMMAND="${EMBEDDED_DIR}/bin/gem"

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

VAGRANT_GEM_PATH="${DIR}/../vagrant.gem"

# Work in a temporary directory
TMP_DIR=$(mktemp -d tmp.XXXXXXXXX)
pushd $TMP_DIR

if [ ! -f "${VAGRANT_GEM_PATH}" ]; then
    # Download Vagrant and extract
    SOURCE_REPO=${VAGRANT_REPO:-hashicorp/vagrant}
    SOURCE_PREFIX=${SOURCE_REPO/\//-}
    SOURCE_URL="https://api.github.com/repos/${SOURCE_REPO}/tarball/${VAGRANT_REV}"
    if [ -z "${VAGRANT_TOKEN}" ]; then
        curl -L ${SOURCE_URL} > vagrant.tar.gz
    else
        curl -L -u "${VAGRANT_TOKEN}:x-oauth-basic" ${SOURCE_URL} > vagrant.tar.gz
    fi
    rm -rf ${SOURCE_PREFIX}-*
    tar xzf vagrant.tar.gz
    rm vagrant.tar.gz
    cd ${SOURCE_PREFIX}-*

    # If we have a version file, use that. Otherwise, use a timestamp
    # on version 0.1.
    if [ ! -f "version.txt" ]; then
        echo -n "0.1.0" > version.txt
    fi
    VERSION=$(cat version.txt | sed -e 's/\.[^0-9]*$//')
    echo -n $VERSION >"${VERSION_OUTPUT}"

    # Build the gem
    ${GEM_COMMAND} build vagrant.gemspec
    cp vagrant-*.gem vagrant.gem
else
    cp "${VAGRANT_GEM_PATH}" ./vagrant.gem
    ${GEM_COMMAND} unpack ./vagrant.gem
    VERSION=$(cat vagrant/version.txt | sed -e 's/\.[^0-9]*$//')
    echo -n $VERSION >"${VERSION_OUTPUT}"
fi

# We want to use the system libxml/libxslt for Nokogiri
export NOKOGIRI_USE_SYSTEM_LIBRARIES=1

# Install the gem. Export all these environmental variables so the Gem
# goes into the proper place.
export GEM_PATH="${EMBEDDED_DIR}/gems/${VERSION}"
export GEM_HOME="${GEM_PATH}"
export GEMRC="${EMBEDDED_DIR}/etc/gemrc"
export CPPFLAGS="-I${EMBEDDED_DIR}/include -I${EMBEDDED_DIR}/include/libxml2"
export CFLAGS="${CPPFLAGS}"
export LDFLAGS="-L${EMBEDDED_DIR}/lib -L${EMBEDDED_DIR}/lib64"
export PATH="${EMBEDDED_DIR}/bin:${PATH}"
export SSL_CERT_FILE="${EMBEDDED_DIR}/cacert.pem"
export PKG_CONFIG_PATH="${EMBEDDED_DIR}/lib/pkgconfig"

mkdir -p "${EMBEDDED_DIR}/certs"
# Install the pkg-config gem to ensure system can read the bundled *.pc files
${GEM_COMMAND} install pkg-config --no-document -v "~> 1.1.7"

${GEM_COMMAND} install vagrant.gem --no-document

# Install extensions
# ${GEM_COMMAND} install vagrant-share --force --no-document --conservative --clear-sources --source "https://gems.hashicorp.com"

# Setup the system plugins
cat <<EOF >${EMBEDDED_DIR}/plugins.json
{
    "version": "1",
    "installed": {
    }
}
EOF
chmod 0644 ${EMBEDDED_DIR}/plugins.json

# Setup vagrant manifest
cat <<EOF >${EMBEDDED_DIR}/manifest.json
{
    "vagrant_version": "${VERSION}"
}
EOF
chmod 0644 ${EMBEDDED_DIR}/manifest.json

# Darwin
# if [[ "$OSTYPE" == "darwin"* ]]; then
#     for lib_path in $(find "${EMBEDDED_DIR}/gems" -name "*.bundle"); do
#         for scrub_path in $(otool -l "${lib_path}" | grep "^ *path" | awk '{print $2}' | uniq); do
#             install_name_tool -rpath "${scrub_path}" "@executable_path/../lib" "${lib_path}"
#         done
#     done
# else
#     for so_path in $(find "${EMBEDDED_DIR}/gems" -name "*.so"); do
#         set +e
#         chrpath --list "${so_path}"
#         if [ $? -eq 0 ]; then
#             echo "-> ${so_path}"
#             set -e
#             so_dir=$(dirname "${so_path}")
#             rel_embedded=$(relpath "${so_dir}" "${EMBEDDED_DIR}")
#             rpath="\$ORIGIN/${rel_embedded}/lib:\$ORIGIN/${rel_embedded}/lib64"
#             chrpath --replace "${rpath}" "${so_path}"
#             chrpath --convert "${so_path}"
#         fi
#     done
#     set -e
# fi

# Exit the temporary directory
popd
rm -rf ${TMP_DIR}
