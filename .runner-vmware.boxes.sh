#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

mkdir -p ${DIR}/pkgs

pushd ${DIR}/packer/vagrant

DEFAULT_LIST=$(ls template*.json)
BUILD_BOXES=${BUILD_BOXES:-$DEFAULT_LIST}
PACKER_VERSION=${PACKER_VERSION:-1.2.2}

set -ex

if [ "${INSTALL_PACKER}" != "" ]
then
    curl -o packer.zip "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip"
    unzip packer.zip
    mv packer /usr/local/bin/packer
fi

for box in ${BUILD_BOXES}
do
    set +ex
    echo "${box}" | grep i386
    set -ex
    if [ $? -eq 0 ]
    then
        base=$(echo "${box}" | sed 's/-i386//')
        echo packer build -var-file=${box} ${base}
    else
        echo packer build ${box}
    fi
done

mv *.box ${DIR}/pkgs/

popd
