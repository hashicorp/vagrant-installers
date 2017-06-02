#!/usr/bin/bash

pushd /home/vagrant/styrene
touch i-am-running
./styrene.sh --no-exe --color=no vagrant.cfg
ls *.zip
if [[ $? -ne 0 ]]; then
    ./styrene.sh --no-exe --color=no vagrant.cfg
fi
mkdir substrate
mv *.zip substrate/substrate-asset.zip
pushd substrate
unzip -q substrate-asset.zip
rm -rf _scripts etc var tmp usr/var *.zip
mv * /c/vagrant-substrate/staging/embedded/
popd
rm -rf substrate
touch substrate-complete
popd
