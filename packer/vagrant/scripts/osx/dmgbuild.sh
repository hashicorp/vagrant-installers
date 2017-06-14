#!/bin/sh

pushd /tmp
su vagrant -c "brew install python"
rm /usr/bin/python
ln -s /usr/local/bin/python /usr/bin/python
su vagrant -c "brew install /private/tmp/dmgbuild.rb"
popd
