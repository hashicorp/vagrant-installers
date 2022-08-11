#!/usr/bin/env bash
#
# NOTE: THIS SCRIPT SHOULD NOT BE CALLED DIRECTLY. CALL THE ROOT
# "package.sh" instead.
#
# This is a wrapper that is able to install a version of Vagrant into
# the substrate. Once this command runs, the substrate directory it is
# pointed to is no longer valid.

function fail() {
    echo "ERROR: ${1}"
    exit 1
}

function relpath() {
    path_to="$(readlink -f "$2")"
    source="$(readlink -f "$1")"
    rel=$(perl -MFile::Spec -e "print File::Spec->abs2rel(q($path_to),q($source))")
    echo "${rel}"
}

# Verify arguments
if [ "$#" -ne "3" ]; then
  echo "Usage: $0 SUBSTRATE-DIR VAGRANT-REVISION VERSION-FILE" >&2
  exit 1
fi

SUBSTRATE_DIR="${1}"
EMBEDDED_DIR="${SUBSTRATE_DIR}/embedded"
VAGRANT_REV="${2}"
VERSION_OUTPUT="${3}"

export GEM_COMMAND="${EMBEDDED_DIR}/bin/gem"

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

VAGRANT_GEM_PATH="${DIR}/../vagrant.gem"

if [[ "${OSTYPE}" == "darwin"* ]]; then
    VAGRANT_GO_PATH=("${DIR}/../vagrant-go_"*darwin*)
else
    if command -v arch; then
        ARCH=$(arch | perl -ne 'chomp and print')
        if [[ "${ARCH}" == "x86_64" ]]; then
            VAGRANT_GO_PATH=("${DIR}/../vagrant-go_"*linux_amd64)
        else
            VAGRANT_GO_PATH=("${DIR}/../vagrant-go_"*linux_386)
        fi
    else
        VAGRANT_GO_PATH=("${DIR}/../vagrant-go_"*linux_amd64)
    fi
fi

# Work in a temporary directory
TMP_DIR="$(mktemp -d "$(pwd)/tmp.XXXXXXXXX")"
pushd "${TMP_DIR}" ||
    fail "Failed to move into temporary directory"

if [ ! -f "${VAGRANT_GEM_PATH}" ]; then
    # Download Vagrant and extract
    SOURCE_REPO=${VAGRANT_REPO:-hashicorp/vagrant}
    SOURCE_PREFIX=${SOURCE_REPO/\//-}
    SOURCE_URL="https://api.github.com/repos/${SOURCE_REPO}/tarball/${VAGRANT_REV}"
    if [ -z "${VAGRANT_TOKEN}" ]; then
        curl -f -L "${SOURCE_URL}" > vagrant.tar.gz ||
            fail "Failed to download Vagrant tarball"
    else
        curl -f -L -u "${VAGRANT_TOKEN}:x-oauth-basic" "${SOURCE_URL}" > vagrant.tar.gz ||
            fail "Failed to download Vagrant tarball"
    fi
    rm -rf "${SOURCE_PREFIX}-"*
    tar xzf vagrant.tar.gz || fail "Failed to unpack Vagrant tarball"
    rm vagrant.tar.gz
    pushd "${SOURCE_PREFIX}-"* || fail "Failed to enter Vagrant source directory"

    # If we have no version file, bail
    if [ ! -f "version.txt" ]; then
        fail "Could not locate version file in Vagrant source"
    fi
    VERSION="$(<version.txt)"
    echo -n "${VERSION}" > "${VERSION_OUTPUT}"

    # Build the gem
    ${GEM_COMMAND} build vagrant.gemspec || fail "Failed to build Vagrant gem"
    cp vagrant-*.gem vagrant.gem || fail "Failed to relocate Vagrant gem"
    git submodule --init --recursive || fail "Failed to install submodule dependencies"
    make bin || fail "Failed to build the vagrant-go binary"
    mv vagrant vagrant-go || fail "Failed to relocate the vagrant-go binary"
else
    cp "${VAGRANT_GO_PATH}" ./vagrant-go || fail "Failed to relocate vagrant-go binary"
    cp "${VAGRANT_GEM_PATH}" ./vagrant.gem || fail "Failed to relocate Vagrant gem"
    ${GEM_COMMAND} unpack ./vagrant.gem || fail "Failed to unpack Vagrant gem"
    VERSION="$(<vagrant/version.txt)"
    echo -n "${VERSION}" > "${VERSION_OUTPUT}"
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
${GEM_COMMAND} install pkg-config --no-document -v "~> 1.1.7" ||
    fail "Failed to install pkg-config gem"

${GEM_COMMAND} install vagrant.gem --no-document ||
    fail "Failed to install the vagrant gem"

# Install extensions
# ${GEM_COMMAND} install vagrant-share --force --no-document --conservative --clear-sources --source "https://gems.hashicorp.com"

# Install Vagrant go binary to bin dir
mv vagrant-go "${SUBSTRATE_DIR}"/bin/vagrant-go ||
    fail "Failed to install the vagrant-go binary"

# Setup the system plugins
cat <<EOF >"${EMBEDDED_DIR}/plugins.json"
{
    "version": "1",
    "installed": {
    }
}
EOF
chmod 0644 "${EMBEDDED_DIR}/plugins.json" ||
    fail "Could not set plugins.json permission"

# Setup vagrant manifest
cat <<EOF >"${EMBEDDED_DIR}/manifest.json"
{
    "vagrant_version": "${VERSION}"
}
EOF
chmod 0644 "${EMBEDDED_DIR}/manifest.json" ||
    fail "Could not set manifest.json permission"

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
# (we really don't care if this fails)
# shellcheck disable=SC2164
popd
rm -rf "${TMP_DIR}"
