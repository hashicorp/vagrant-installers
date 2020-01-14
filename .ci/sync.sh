#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/common.sh"

export PATH="${PATH}:${root}/.ci"

pushd "${root}" > "${output}"

if [ "${repo_name}" = "${vagrant-installers}" ]; then
    remote_repository="hashicorp/vagrant-builders"
else
    remote_repository="hashicorp/vagrant-installers"
fi

wrap git remote add mirror "https://${HASHIBOT_USER}:${HASHIBOT_TOKEN}@github.com/${remote_repository}" \
     "Failed to add mirror repository (${remote_repository}) for sync"
wrap git update \
     "Failed to update mirror repository (${remote_repository}) for sync"
wrap git push mirror master \
     "Failed to sync mirror repository (${remote_repository})"
