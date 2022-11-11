#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/load-ci.sh"

pushd "${root}"

if [ -z "${release}" ]; then
    echo "Not creating release: this is a dev build"
    exit
fi

mkdir -p ./pkg

if [ -n "${PACKAGES_IDENTIFIER}" ]; then
    pushd pkg
    github_draft_release_assets "${repo_owner}" "${repo_name}" "${PACKAGES_IDENTIFIER}"
    popd
else
    fail "No identifier defined for packages"
fi

# Otherwise, this is a proper release, so invoke the hashicorp release
echo "Releasing new version of Vagrant to HashiCorp releases - v${vagrant_version}"
hashicorp_release pkg/ vagrant "${vagrant_version}"

slack -m "New Vagrant release has been published! - *${vagrant_version}*\n\nAssets: https://releases.hashicorp.com/vagrant/${vagrant_version}"
