#!/usr/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


echo "Install ruby build dependencies"

pushd ./ruby-build

makepkg-mingw --syncdeps --noextract --nocheck --noprepare --nobuild --noconfirm
