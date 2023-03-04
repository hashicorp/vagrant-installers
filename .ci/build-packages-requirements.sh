#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/load-ci.sh"

pushd "${root}"

# Download the Vagrant RubyGem and vagrant-go
# binaries. These come from different locations
# depending on how the job was invoked. If the
# VAGRANT_REF environment variable is set, it was
# invoked from a non-release job and the artifacts
# will be retrieved from a draft release on the
# Vagrant repository. If a tag is set, then the
# artifacts will be in a proper release within the
# builders repository. Otherwise, we grab the
# artifacts from the "main" draft release in the
# Vagrant repository
if [ -n "${VAGRANT_REF}" ]; then
    github_draft_release_assets "hashicorp" "vagrant" "${VAGRANT_REF}"
elif [ -n "${tag}" ]; then
    github_release_assets "hashicorp" "vagrant-builders" "${tag}"
else
    github_draft_release_assets "hashicorp" "vagrant" "main"
fi
