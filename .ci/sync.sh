#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/common.sh"

export PATH="${PATH}:${root}/.ci"

pushd "${root}" > "${output}"

if [ "${repo_name}" = "vagrant-installers" ]; then
    remote_repository="hashicorp/vagrant-builders"
else
    remote_repository="hashicorp/vagrant-installers"
fi

echo "Updating repository origin to mirror repository `${remote_repository}`..."
wrap git remote set-url origin "https://${HASHIBOT_USERNAME}:${HASHIBOT_TOKEN}@github.com/${remote_repository}" \
     "Failed to update repository origin to `${remote_repository}` for sync"

echo "Updating configured remotes..."
wrap_stream git remote update \
            "Failed to update mirror repository (${remote_repository}) for sync"

echo "Pulling master from mirror..."
wrap_stream git pull origin master \
            "Failed to pull master from mirror repository (${remote_repository}) for sync"

echo "Pushing master to mirror..."
wrap_stream git push origin master \
            "Failed to sync mirror repository (${remote_repository})"
