#!/bin/bash -eux
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


echo '==> Configuring sshd_config options'

echo '==> Turning off sshd DNS lookup to prevent timeout delay'
echo "UseDNS no" >> /etc/ssh/sshd_config
echo '==> Disablng GSSAPI authentication to prevent timeout delay'
echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config
