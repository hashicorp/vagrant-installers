#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


TOOLS_PATH="/private/tmp/darwin.iso"
if [ ! -e "$TOOLS_PATH" ]; then
    echo "Couldn't locate uploaded tools iso at $TOOLS_PATH!"
    exit 1
fi

TMPMOUNT=`/usr/bin/mktemp -d /tmp/vmware-tools.XXXX`
hdiutil attach "$TOOLS_PATH" -mountpoint "$TMPMOUNT"

INSTALLER_PKG="$TMPMOUNT/Install VMware Tools.app/Contents/Resources/VMware Tools.pkg"
if [ ! -e "$INSTALLER_PKG" ]; then
    echo "Couldn't locate VMware installer pkg at $INSTALLER_PKG!"
    exit 1
fi

echo "Installing VMware tools.."
installer -pkg "$TMPMOUNT/Install VMware Tools.app/Contents/Resources/VMware Tools.pkg" -target /

# This usually fails
hdiutil detach "$TMPMOUNT"
rm -rf "$TMPMOUNT"
rm -f "$TOOLS_PATH"
rm -f darwin.iso

# Point Linux shared folder root to that used by OS X guests,
# useful for the Hashicorp vmware_fusion Vagrant provider plugin
mkdir /mnt
ln -sf /Volumes/VMware\ Shared\ Folders /mnt/hgfs
