#!/usr/bin/env bash

function cleanup {
    vagrant destroy --force
}

trap cleanup EXIT

set -ex

guests=$(vagrant status | grep vmware | awk '{print $1}')
for guest in ${guests}
do
    vagrant up ${guest} --no-provision
done

set +e
declare -A pids

for guest in ${guests}
do
    vagrant provision ${guest}
    pids[guest]=$!
done

result=0

for guest in ${guests}
do
    wait ${pids[guest]}
    if [ $? -ne 0 ]
    then
        echo "Provision failure for: ${guest}"
        result=1
    fi
done

mkdir -p assets
mv -f substrate-assets/* assets/
mv -f pkg/* assets/

exit $result
