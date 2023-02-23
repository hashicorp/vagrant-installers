#!/bin/sh


OUTPUT_DIR="${VAGRANT_SUBSTRATE_OUTPUT_DIR:-substrate-assets}"
mkdir -p "/vagrant/${OUTPUT_DIR}"
chmod 755 /vagrant/substrate/run.sh

su vagrant -l -c 'brew install wget'

# grab new cacert
# curl -o cacert.pem https://curl.se/ca/cacert.pem
# mkdir -p /usr/local/etc/openssl
# chown vagrant:admin /usr/local/etc/openssl

# mv cacert.pem /usr/local/etc/openssl/cacert.pem

#export SSL_CERT_FILE=/usr/local/etc/openssl/cacert.pem
export PATH="$PATH:/usr/local/bin:/usr/local/go/bin"

set -e

/vagrant/substrate/run.sh "/vagrant/${OUTPUT_DIR}"
