#!/usr/bin/env bash

function cleanup {
    vagrant destroy --force
}

trap cleanup EXIT

GEM_PATH=$(ls vagrant-[0-9].[0-9].[0-9]*.gem)

set -ex

if [ -f "${GEM_PATH}" ]
then
    mv "${GEM_PATH}" package/vagrant.gem
fi

vagrant box update
vagrant box prune

guests=$(vagrant status | grep vmware | awk '{print $1}')

vagrant up --no-provision

set +e
declare -A pids

for guest in ${guests}
do
    vagrant provision ${guest} &
    pids[$guest]=$!
    sleep 10
done

result=0

for guest in ${guests}
do
    wait ${pids[$guest]}
    if [ $? -ne 0 ]
    then
        echo "Provision failure for: ${guest}"
        result=1
    else
        echo "Provision complete for: ${guest}"
    fi
done

mkdir -p assets

if [ "${VAGRANT_BUILD_TYPE}" = "package" ]
then
    mv -f pkg/* assets/
else
    mv -f substrate-assets/* assets/
fi

exit $result
