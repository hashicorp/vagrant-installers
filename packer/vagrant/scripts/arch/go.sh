#!/bin/sh

sudo pacman --noconfirm -Sy go git zip
sudo mkdir -p /usr/local/go/bin
sudo ln -s /usr/bin/go /usr/local/go/bin/go
