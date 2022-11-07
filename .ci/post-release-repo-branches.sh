#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/load-ci.sh"

pushd "${root}"

if [ -z "${release}" ]; then
    echo "Not updating Vagrant repository: this is a dev build"

echo -n "Cloning Vagrant repository for signing process... "
wrap git clone "https://${HASHIBOT_USERNAME}:${HASHIBOT_TOKEN}@github.com/hashicorp/vagrant" vagrant-source \
     "Failed to clone Vagrant repository"
pushd vagrant-source

# Now that we have published the new version we need to create
# a new branch for the versioned docs and push the gem as a release
# into the vagrant repository.
mapfile -t tags < <(git tag -l --sort=-v:refname) # this provides tag list in ascending order
tag_len="${#tags[@]}"
for ((i=0; i < "${tag_len}"; i++))
do
    if [ "$("${root}/.ci/semver" "${vagrant_version}" "${tags[i]}")" -eq "1" ]; then
        idx=$i
        break
    fi
done
if [ -z "${idx}" ]; then
    fail "Failed to determine previous version from current release - ${vagrant_version}"
fi
previous_version="${tags[$idx]}"
if [ -z "${previous_version}" ]; then
    fail "Previous version detection did not provide valid result. (Current release: ${vagrant_version})"
fi
previous_version="${previous_version:1:${#previous_version}}" # remove 'v' prefix

# Now that we have the previous version, checkout the stable-website
# branch and create a new release branch.
release_branch="release/${previous_version}"
release_minor_branch="release/${previous_version%.*}.x"
echo "Creating a new ${release_branch} branch..."

wrap git checkout stable-website \
     "Failed to checkout stable-website branch"
wrap git checkout -b "${release_branch}" \
     "Failed to create new branch: ${release_branch}"
wrap git push origin "${release_branch}" \
     "Failed to push new branch: ${release_branch}"

echo "Creating a new ${release_minor_branch} branch..."
wrap git checkout stable-website \
     "Failed to checkout stable-website branch"
# The release minor branch will likely not exist locally but
# just be sure it's not there
git branch -d "${release_minor_branch}" > "${output}" 2>&1

wrap git checkout -b "${release_minor_branch}" \
     "Failed to create new branch: ${release_minor_branch}"
wrap git push -f origin "${release_minor_branch}" \
     "Failed to push new branch: ${release_minor_branch}"

slack -m "New branches created for previous release: ${release_branch} and ${release_minor_branch}"

# Now update the stable-website branch with new version content
echo "Updating stable-website with latest..."
wrap git checkout "v${vagrant_version}" \
     "Failed to checkout vagrant release v${vagrant_version}"
wrap git branch -d stable-website \
    "Failed to delete the stable-website branch"
wrap git checkout -b stable-website \
     "Failed to create new stable-website branch from release v${vagrant_version}"
wrap git push -f origin stable-website \
     "Failed to push updated stable-website branch"

slack -m "Vagrant website changes have been pushed for release ${vagrant_version}"
