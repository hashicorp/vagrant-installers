#!/usr/bin/env bash

set -e

/vagrant/package/appimage.sh

mkdir -p /vagrant/pkg
chown vagrant:vagrant *.zip
mv *.zip /vagrant/pkg
