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

# Fetch the gem
github_release_assets "hashicorp" "vagrant-builders" "${tag}" ".gem"

# If this is an annotated tag, git the proper commit-ish value
commitish=$(git ls-remote --tags https://github.com/hashicorp/vagrant "v${vagrant_version}^{}") ||
    fail "Annotated tag check failed"

# If we got a commitish value, trim it and use it for the full_sha
# value since the tag is annotated. Otherwise, just use the tag.
if [ -n "${commitish}" ]; then
    full_sha="${commitish%%[[:space:]]*}"
else
    full_sha="v${vagrant_version}"
fi

# Override local variables to create release on vagrant repository
repo_owner="hashicorp"
repo_name="vagrant"
export GITHUB_TOKEN="${HASHIBOT_TOKEN}"

release "v${vagrant_version}" ./"vagrant-${vagrant_version}.gem"

slack -m "New Vagrant GitHub release created for v${vagrant_version} - release process complete."
