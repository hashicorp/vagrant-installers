#!/bin/sh

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"

OUTPUT_DIR="${VAGRANT_SUBSTRATE_OUTPUT_DIR:-substrate-assets}"
mkdir -p /vagrant/${OUTPUT_DIR}
chmod 755 /vagrant/substrate/run.sh

TRAVIS=1 su vagrant -l -c 'brew update'
TRAVIS=1 su vagrant -l -c 'brew install wget'

# grab new cacert
curl -o cacert.pem https://curl.haxx.se/ca/cacert.pem
chown vagrant:admin /usr/local/etc/openssl

mkdir -p /usr/local/etc/openssl

mv cacert.pem /usr/local/etc/openssl/cacert.pem

export SSL_CERT_FILE=/usr/local/etc/openssl/cacert.pem
export PATH=$PATH:/usr/local/bin:/usr/local/go/bin

set -e

if [ "${VAGRANT_BUILD_DEBUG}" = "1" ]; then
    /vagrant/substrate/run.sh /vagrant/${OUTPUT_DIR}
else
    /vagrant/substrate/run.sh /vagrant/${OUTPUT_DIR} > /dev/null
fi
