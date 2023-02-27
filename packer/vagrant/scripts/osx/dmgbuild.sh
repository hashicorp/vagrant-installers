#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


pushd /private/tmp
su vagrant -c "/usr/local/bin/brew install python"
rm /usr/bin/python
ln -s /usr/local/bin/python /usr/bin/python
su vagrant -c "/usr/local/bin/brew install /private/tmp/dmgbuild.rb"
popd
