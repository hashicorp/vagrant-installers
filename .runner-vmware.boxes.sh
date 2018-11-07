#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

mkdir -p ${DIR}/assets

pushd ${DIR}/packer/vagrant

DEFAULT_LIST=$(ls template*.json)
BUILD_BOXES=${BUILD_BOXES:-$DEFAULT_LIST}
PACKER_VERSION=${PACKER_VERSION:-1.3.2}

set -e

if [ "${INSTALL_PACKER}" != "" ]
then
    apt-get install -yq unzip
    curl -o packer.zip "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip"
    unzip packer.zip
    mv packer /usr/local/bin/packer
fi

for box in ${BUILD_BOXES}
do
    if [[ "${box}" = *"i386"* ]]; then
        base=$(echo "${box}" | sed 's/-i386//')
        packer build -var-file=${box} ${base}
    else
        packer build ${box}
    fi
done

mv *.box ${DIR}/assets/

popd
