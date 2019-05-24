#!/usr/bin/env bash

function cleanup {
    if [ "${VAGRANT_AUTO_DESTROY}" == "1" ]; then
        vagrant destroy --force > /dev/null 2>&1
    fi
    for logfile in `ls .output-*`
    do
        guest="${logfile##.output-}"
        if [ "${VAGRANT_ONLY_BOXES}" != "" ]; then
            if [ "${VAGRANT_ONLY_BOXES}" != "${guest}" ]; then
                continue
            fi
        fi
        (>&2 echo "Failed to provision: ${guest}")
        sed -i -E '/^[[:space:]]+from \//d' "${logfile}"
        output=$(tail -n 5 "${logfile}")
        (>&2 echo "${output}")
    done
}

trap cleanup EXIT

GEM_PATH=$(ls vagrant-*.gem)

set -e

if [ -f "${GEM_PATH}" ]
then
    mv "${GEM_PATH}" package/vagrant.gem
fi

vagrant box update
vagrant box prune

guests=$(vagrant status | grep vmware | awk '{print $1}')

vagrant up --no-provision

declare -A upids

if [ "${PACKET_EXEC}" == "1" ]; then
    # macos uploads
    if [ -f "MacOS_CodeSigning.cert" ]; then
        if [[ "${guests[*]}" = *"osx"* ]]; then
            vagrant upload MacOS_CodeSigning.cert "/tmp/" osx-10.9
            vagrant upload MacOS_CodeSigning.key "/tmp/" osx-10.9
            export VAGRANT_INSTALLER_VAGRANT_PACKAGE_SIGN_CERT_PATH="/tmp/MacOS_CodeSigning.cert"
            export VAGRANT_INSTALLER_VAGRANT_PACKAGE_SIGN_KEY_PATH="/tmp/MacOS_CodeSigning.key"
        fi
    fi
    # win uploads
    if [ -f "Win_CodeSigning.p12" ]; then
        if [[ "${guests[*]}" = *"win"* ]]; then
            vagrant upload Win_CodeSigning.p12 "~/" win-7
            export VAGRANT_INSTALLER_SignKeyPath="C:\\Users\\vagrant\\Win_CodeSigning.p12"
        fi
    fi
fi

set +e
declare -A pids

for guest in ${guests}
do
    vagrant provision ${guest} > .output-${guest} 2>&1 &
    pids[$guest]=$!
    until [ -f ".output-${guest}" ]; do
        sleep 0.1
    done
    tail --quiet --pid ${pids[$guest]} -f .output-${guest} &
done

result=0

for guest in ${guests}
do
    wait ${pids[$guest]}
    result=$?
    if [ $result -ne 0 ]
    then
        echo "Provision failure for: ${guest}"
    else
        echo "Provision complete for: ${guest}"
        rm .output-${guest}
    fi
done

exit $result
