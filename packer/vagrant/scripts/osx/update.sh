#!/bin/bash -eux
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


echo "==> Disable automatic update check"
defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool FALSE

if [[ "$UPDATE" =~ ^(true|yes|on|1|TRUE|YES|ON])$ ]]; then

    echo "==> Running software update"
    softwareupdate --install --all --verbose

    echo "==> Rebooting the machine"
    reboot

fi
