#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/load-ci.sh"

pushd "${root}"

# If this is a release we don't trigger the acceptance tests
if [ -n "${release}" ]; then
    echo "Not triggering acceptance tests: this is not a dev build"
    exit
fi

if [ -z "${prerelease_version}" ]; then
    fail "The 'prerelease_version' environment variable is not set"
fi

echo "Dispatching vagrant-acceptance"

github_repository_dispatch "hashicorp" "vagrant-acceptance" \
    "prerelease" "prerelease_version=${prerelease_version}"
