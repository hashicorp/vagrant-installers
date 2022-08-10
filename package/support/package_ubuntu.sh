#!/usr/bin/env bash

function fail() {
    echo "ERROR: ${1}"
    exit 1
}

# Verify arguments
if [ "$#" -ne "2" ]; then
  echo "Usage: $0 SUBSTRATE-DIR VAGRANT-VERSION" >&2
  exit 1
fi

SUBSTRATE_DIR="${1}"
VAGRANT_VERSION="${2}"
if [ "$(arch)" = "x86_64" ]; then
  ARCH="amd64"
else
  ARCH="i686"
fi
if [ -z "${RELEASE_NUMBER}" ]; then
  RELEASE_NUMBER="1"
fi

OUTPUT_PATH="$(pwd)/vagrant_${VAGRANT_VERSION}-${RELEASE_NUMBER}_${ARCH}.deb"

# Work in a temporary directory
rm -rf package-staging
mkdir -p package-staging
pushd package-staging || fail "Could not enter staging directory"

STAGING_DIR="$(pwd)"

# Make some directories
mkdir -p ./usr/bin
mkdir -p ./opt/vagrant
mv "${SUBSTRATE_DIR}/bin" ./opt/vagrant || fail "Could not move substrate bin dir"
mv "${SUBSTRATE_DIR}/embedded" ./opt/vagrant || fail "Could not move substrate embedded dir"

# Create the Linux script proxy
cat <<EOF >./usr/bin/vagrant
#!/usr/bin/env bash
#
# This script just forwards all arguments to the real vagrant binary.

/opt/vagrant/bin/vagrant "\$@"
EOF
chmod +x ./usr/bin/vagrant || fail "Could not set vagrant script executable"

# Create the Linux script proxy for vagrant-go
cat <<EOF >./usr/bin/vagrant-go
#!/usr/bin/env bash
#
# This script just forwards all arguments to the real vagrant-go binary.

/opt/vagrant/bin/vagrant-go "\$@"
EOF
chmod +x ./usr/bin/vagrant-go || fail "Could not set vagrant-go script executable"

# Package it up!
fpm -p "${OUTPUT_PATH}" \
  -n vagrant \
  -v "${VAGRANT_VERSION}" \
  -s dir \
  -t deb \
  --prefix '/' \
  --maintainer "HashiCorp <support@hashicorp.com>" \
  --url "https://www.vagrantup.com/" \
  --epoch 1 \
  --deb-user root \
  --deb-group root \
  . || fail "Failed to build package"

# Exit the directory and clean it
# (we really don't care if this fails)
# shellcheck disable=SC2164
popd
rm -rf "${STAGING_DIR}"
