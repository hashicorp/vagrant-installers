#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


set +e

if uname -m | grep x86_64 > /dev/null 2>&1; then
    ARCH="amd64"
else
    ARCH="386"
fi

set -e

wget -O go.tar.gz "https://dl.google.com/go/go${GO_INSTALL_VERSION}.linux-${ARCH}.tar.gz"
tar -C /usr/local -xzf go.tar.gz

echo "export PATH=$PATH:/usr/local/go/bin" > /etc/profile.d/go-path.sh
echo "export PATH=$PATH:/usr/local/go/bin" >> /home/vagrant/.bash_profile
chmod 755 /etc/profile.d/go-path.sh

ln -s /usr/local/go/bin/go /usr/local/bin/
