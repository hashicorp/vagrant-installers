#!/usr/bin/bash

echo "Install ruby build dependencies"

pushd ./ruby-build

makepkg-mingw --syncdeps --noextract --nocheck --noprepare --nobuild --noconfirm
