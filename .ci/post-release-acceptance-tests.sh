#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/load-ci.sh"

pushd "${root}"

# If this is not a release build, push the prerelease to GitHub
if [ -n "${release}" ]; then
    echo "Not triggering acceptance tests: this is not a dev build"
    exit
fi

if [ -n "${tag}" ]; then
    prerelease_version="${tag}"
else
    prerelease_version="v${vagrant_version}+${ident_ref}"
fi

echo "Generating GitHub pre-release packages for Vagrant version ${prerelease_version}... "
# NOTE: We always want to store builds into the vagrant-installers repository since they should
# be publicly accessible
export repo_name="vagrant-installers"
export GITHUB_TOKEN="${HASHIBOT_TOKEN}"
prerelease "${prerelease_version}" pkg/

slack -m "New Vagrant development installers available:\n> https://github.com/${repo_owner}/${repo_name}/releases/${prerelease_version}"

echo "Dispatching vagrant-acceptance"

github_repository_dispatch "hashicorp" "vagrant-acceptance" \
    "prerelease" "prerelease_version=${prerelease_version}"
