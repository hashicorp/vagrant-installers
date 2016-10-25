#!/usr/bin/env bash
set -e

# Verify arguments
if [ "$#" -ne "2" ]; then
  echo "Usage: $0 SUBSTRATE-DIR VAGRANT-VERSION" >&2
  exit 1
fi

SUBSTRATE_DIR=$1
VAGRANT_VERSION=$2
ARCH=$(uname -p | perl -ne 'chomp and print')
OUTPUT_PATH="`pwd`/vagrant_${VAGRANT_VERSION}_${ARCH}.txz"

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
FPM=`which fpm` ||  FPM="$GEM_HOME/bin/fpm"
$FPM -p ${OUTPUT_PATH} \
  -n vagrant \
  -v $VAGRANT_VERSION \
  -s dir \
  -t freebsd \
  --prefix '/' \
  --maintainer "HashiCorp <support@hashicorp.com>" \
  --url "https://www.vagrantup.com/" \
  --epoch 1 \
  --freebsd-origin "sysutils/vagrant" \
  .

# Workaround for FPM 1.5.0 (#1093 -- fpm/freebsd ignores option -p)
# #1093 causes that the output file is written to current working directory
# See: https://github.com/jordansissel/fpm/pull/1093
if [ -f "./vagrant-${VAGRANT_VERSION}_1.txz" ]
then
  cp "./vagrant-${VAGRANT_VERSION}_1.txz"  "${OUTPUT_PATH}"
fi

# Exit the directory and clean it
popd
rm -rf $STAGING_DIR
