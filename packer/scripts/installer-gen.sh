#!/bin/bash

GENDIR=/opt/vagrant-installer-gen

# Make the directory that'll contain our installer generator
# and start setting that up.
mkdir -p $GENDIR
chmod 0777 $GENDIR
cd $GENDIR
git clone \
    --depth=1 \
    https://github.com/mitchellh/vagrant-installers.git .

# Done!
echo 'Done! Vagrant installer generators are ready.'
