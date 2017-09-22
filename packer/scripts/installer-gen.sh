#!/bin/bash

GENDIR=/opt/vagrant-installer

# Make the directory that'll contain our installer generator
# and start setting that up.
mkdir -p $GENDIR
chmod 0777 $GENDIR
cd $GENDIR
git clone \
    --depth=1 \
    https://github.com/hashicorp/vagrant-installers.git .

# Done!
echo 'Done! Vagrant installer generators are ready.'
