#!/bin/sh

uname -m | grep x86_64

if [[ $? -eq 0 ]]
then
    ARCH="amd64"
else
    ARCH="386"
fi

wget --no-check-certificate -O go.tar.gz "https://storage.googleapis.com/golang/go1.8.1.linux-${ARCH}.tar.gz"
tar -C /usr/local -xzf go.tar.gz
