#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


set -e
set -x

date | sudo tee /etc/vagrant_box_build_time

mkdir -p ~/.ssh
curl -fsSLo ~/.ssh/authorized_keys https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub
chmod 700 ~/.ssh/
chmod 600 ~/.ssh/authorized_keys
