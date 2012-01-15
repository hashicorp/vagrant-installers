#!/bin/sh

echo $2 > /tmp/foo
ln -Fs $2/bin/vagrant /usr/bin/vagrant
exit 0
