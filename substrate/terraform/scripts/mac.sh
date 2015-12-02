#!/bin/bash

# Go into the folder with our data
cd /opt/vagrant-installer-gen

# Update it
git pull

# Build the substrate
sudo rm -rf /vagrant-substrate
sudo ./substrate/run.sh /tmp
