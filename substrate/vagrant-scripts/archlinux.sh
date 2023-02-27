#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


OUTPUT_DIR="${VAGRANT_SUBSTRATE_OUTPUT_DIR:-substrate-assets}"
mkdir -p "/vagrant/${OUTPUT_DIR}"
chmod 755 /vagrant/substrate/run.sh

set -e

/vagrant/substrate/run.sh "/vagrant/${OUTPUT_DIR}"
