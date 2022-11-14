#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/load-ci.sh"

pushd "${root}"

# Only create a release on the Vagrant repository if this
# is a proper release
if [ -z "${release}" ]; then
    echo "Not creating Vagrant repository release: this is a dev build"
    exit
fi

# Override local variables to create release on vagrant repository
repo_owner="hashicorp"
repo_name="vagrant"
full_sha="v${vagrant_version}"
export GITHUB_TOKEN="${HASHIBOT_TOKEN}"

release "v${vagrant_version}" ./"vagrant-${vagrant_version}.gem"

slack -m "New Vagrant GitHub release created for v${vagrant_release} - release process complete."
