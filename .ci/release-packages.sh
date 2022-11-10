#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/load-ci.sh"

pushd "${root}"

mkdir -p ./pkg

if [ -n "${PACKAGES_IDENTIFIER}" ]; then
    pushd pkg
    github_draft_release_assets "${repo_owner}" "${repo_name}" "${PACKAGES_IDENTIFIER}"
    popd
fi

# If this is not a release build, push the prerelease to GitHub
if [ -z "${release}" ]; then
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

    exit
fi

# Otherwise, this is a proper release, so invoke the hashicorp release
echo "Releasing new version of Vagrant to HashiCorp releases - v${vagrant_version}"
hashicorp_release pkg/ vagrant "${vagrant_version}"

slack -m "New Vagrant release has been published! - *${vagrant_version}*\n\nAssets: https://releases.hashicorp.com/vagrant/${vagrant_version}"
