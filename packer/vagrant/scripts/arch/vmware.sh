#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


set -e
set -x

sudo pacman -S --noconfirm open-vm-tools
sudo systemctl enable vmtoolsd
sudo mkdir -p /mnt/hgfs
