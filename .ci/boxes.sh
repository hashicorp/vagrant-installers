#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/common.sh"

pushd "${root}" > "${output}"

echo "Starting packer builds..."
pushd packer/vagrant > "${output}"

IFS=',' read -r -a builds <<< "${PACKER_BUILDS}"
for build in "${builds[@]}"; do
    echo "Building box for ${build}"
    wrap_stream packer build "template_${build}.json" \
                "Failed to build box for ${build}"
    slack -m "New Vagrant installers build box available for: ${build}"
done
