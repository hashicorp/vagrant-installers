#!/bin/sh

# Force a DNS update
echo "dns-nameservers 8.8.8.8" >> /etc/network/interfaces
service network-interface restart INTERFACE=eth0

OUTPUT_DIR="${VAGRANT_SUBSTRATE_OUTPUT_DIR:-substrate-assets}"
mkdir -p "/vagrant/${OUTPUT_DIR}"
chmod 755 /vagrant/substrate/run.sh

set -e

/vagrant/substrate/run.sh "/vagrant/${OUTPUT_DIR}"
