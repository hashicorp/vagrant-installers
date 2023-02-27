#!/bin/bash -eux
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

echo "==> Applying updates"
yum -y update

# reboot
echo "Rebooting the machine..."
reboot
sleep 60
