#!/usr/bin/env bash
set -e

# Verify arguments
if [ "$#" -ne "2" ]; then
  echo "Usage: $0 SUBSTRATE-DIR VAGRANT-VERSION" >&2
  exit 1
fi

SUBSTRATE_DIR=$1
VAGRANT_VERSION=$2
ARCH=$(arch | perl -ne 'chomp and print')
OUTPUT_PATH="`pwd`/vagrant_${VAGRANT_VERSION}_${ARCH}.rpm"

# Work in a temporary directory
rm -rf package-staging
mkdir -p package-staging
STAGING_DIR=$(cd package-staging; pwd)
pushd $STAGING_DIR

# Make some directories
mkdir -p ./usr/bin
mkdir -p ./opt/vagrant
mv ${SUBSTRATE_DIR}/bin ./opt/vagrant
mv ${SUBSTRATE_DIR}/embedded ./opt/vagrant

# Create the Linux script proxy
cat <<EOF >./usr/bin/vagrant
#!/usr/bin/env bash
#
# This script just forwards all arguments to the real vagrant binary.

/opt/vagrant/bin/vagrant "\$@"
EOF
chmod +x ./usr/bin/vagrant

# Package it up!
fpm -p ${OUTPUT_PATH} \
  -n vagrant \
  -v $VAGRANT_VERSION \
  -s dir \
  -t rpm \
  --prefix '/' \
  --rpm-auto-add-directories \
  --maintainer "HashiCorp <support@hashicorp.com>" \
  --epoch 1 \
  --url 'https://www.vagrantup.com' \
  --license 'MIT' \
  --description 'Vagrant is a tool for building and distributing development environments.' \
  -C ${STAGING_DIR} \
  .

# Exit the directory and clean it
popd
rm -rf $STAGING_DIR
