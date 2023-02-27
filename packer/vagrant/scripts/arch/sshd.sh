#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


set -e
set -x

sudo tee -a /etc/ssh/sshd_config <<EOF

UseDNS no
EOF
