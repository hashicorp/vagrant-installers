#!/bin/bash

GENDIR=/opt/vagrant-installer-gen

# Install librarian-puppet so we can get dependencies
gem install --no-ri --no-rdoc librarian-puppet

# Make the directory that'll contain our installer generator
# and start setting that up.
mkdir -p $GENDIR
chmod 0777 $GENDIR
cd $GENDIR
git clone \
    --depth=1 \
    https://github.com/mitchellh/vagrant-installers.git .

# Install the Puppet modules
librarian-puppet install

# Done!
echo 'Done! Vagrant installer generators are ready.'
