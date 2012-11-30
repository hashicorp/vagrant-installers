#!/bin/bash
#
# This script will actually run the puppet code here.
sudo puppet apply \
  --confdir=config/ \
  --modulepath=modules/ \
  manifests/init.pp
