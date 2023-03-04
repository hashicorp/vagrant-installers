#!/bin/bash -eux
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


curl -o go.pkg https://storage.googleapis.com/golang/go1.10.1.darwin-amd64.pkg
sudo installer -pkg ./go.pkg -target /

rm go.pkg
