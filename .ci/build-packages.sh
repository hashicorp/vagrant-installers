#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/load-ci.sh"

pushd "${root}"

# Load these after the CI is loaded since it uses
# CI defined variables
. "${root}/.ci/packaging-vars.sh"

# List of all package artifact suffix values and the
# guest name which will generate them
declare -A package_list=(
    [*amd64.zip]="appimage"
    [*x86_64.pkg.tar.zst]="archlinux"
    [*x86_64.rpm]="centos-6"
    [*i686.rpm]="centos-7-i386"
    [*amd64.dmg]="osx-10.15"
    [*amd64.deb]="ubuntu-14.04"
    [*i686.deb]="ubuntu-14.04-i386"
    [*amd64.msi]="win-8"
    [*i686.msi]="win-8"
)

# Create the package assets directory if it
# doesn't already exist
mkdir -p pkg

# Generate a list of packages we already have (if any)
for p in "${!package_list[@]}"; do
    path=(pkg/${p})
    if [ ! -f "${path[0]}" ]; then
        packages_needed="${packages_needed},${package_list[${p}]}"
    fi
done
packages_needed="${packages_needed#,}"

# If all packages have been built already, we are done
if [ -z "${packages_needed}" ]; then
    echo "All packages are currently built"
    exit
fi

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
    github_release_assets "hashicorp" "vagrant" "${tag}"
else
    github_draft_release_assets "hashicorp" "vagrant" "main"
fi

# Extract out Vagrant version information from gem
vagrant_version="$(gem specification vagrant-*.gem version)" ||
    fail "Failed to ready version from Vagrant RubyGem"
vagrant_version="${vagrant_version##*version: }"

# Unpack all the vagrant-go binaries
for file in ./*; do
    [ -f "${file}" ] || continue
    wrap unzip "${file}" \
        "Failed to unzip vagrant-go binary file (${file})"
    rm -f "${file}"
done

# Place gem into package directory for packaging
wrap cp vagrant-*.gem package/vagrant.gem \
     "Failed to move vagrant RubyGem for packaging"

# Place the go binary into the package directory for packaging
wrap cp vagrant-go_* package/ \
     "Failed to move vagrant go binary for packaging"

# Define a custom cleanup function to destroy any orphan guests
# on the packet instance
function cleanup() {
    unset PACKET_EXEC_PERSIST
    packet-exec run -- pkill -f vmware-vmx
}

# Create the packet device if needed
if ! packet-exec info; then
    wrap_stream packet-exec create \
        "Failed to create packet device"
fi

# Make signing files available
secrets="$(load-signing)" ||
    fail "Failed to load signing files"
eval "${secrets}"

echo "Setting up remote packet device for current job..."

# NOTE: We only need to call packet-exec with the -upload option once
#       since we are persisting the job directory. This dummy command
#       is used simply to seed the work directory.
wrap_stream packet-exec run -upload -- /bin/true \
    "Failed to setup project on remote packet instance"

# Always ensure boxes are up to date
pkt_wrap_stream vagrant box update \
    "Failed to update local build boxes"

# Use this to keep track of our running builds
declare -A package_builds

# Only start guests for substrates that are needed and
# set our build type to package
export PKT_VAGRANT_ONLY_BOXES="${substrates_needed}"
export PKT_VAGRANT_BUILD_TYPE="package"

# If this is a release job signing is _always_ required even
# if the job configuration disabled it
if [ -n "${release}" ]; then
    export PKT_VAGRANT_INSTALLER_VAGRANT_PACKAGE_SIGNING_REQUIRED="1"
fi

echo "Starting Vagrant package guests... "
pkt_wrap_stream vagrant up --no-provision \
    "Failed to start builder guests on packet device for packaging"
echo "Start Vagrant package builds..."

# Load secrets and persist for use
export PACKET_EXEC_PRE_BUILTINS="LoadSecrets"
packet-exec run -quiet -- sleep 500 &
unset PACKET_EXEC_PRE_BUILTINS
# Include a pause here to allow for everything to
# get properly setup
sleep 10

# Now iterate through each package that needs to be built
# and start the provision task on the guest
for p in "${!package_list[@]}"; do
    path=(pkg/${p})
    guest="${package_list[${p}]}"
    if [ -f "${path[0]}" ] || [ -n "${package_builds[${guest}]}" ]; then
        continue
    fi
    echo "Running package build for ${guest}..."
    export PKT_VAGRANT_ONLY_BOXES="${guest}"
    packet-exec run -- vagrant provision "${guest}" > "${guest}.log" 2>&1 &
    pid=$!
    package_builds["${guest}"]="${pid}"
    until [ -f "${guest}.log" ]; do
        sleep 0.1
    done
    tail -f --quiet --pid "${pid}" "${guest}.log" &
done

# Wait for all the background provisions to complete
# NOTE: We don't check pid success since package file check
#       below will catch any errors
for pid in "${package_builds[@]}"; do
    wait "${pid}"
done

# Fetch any built packages
wrap_stream_raw packet-exec run -download "./pkg/*:./pkg" -- /bin/true

# Now that we have finished, destroy any guests we created
echo "Destroying existing Vagrant guests..."
# Clean up the substrate VMs
unset PKT_VAGRANT_ONLY_BOXES
pkt_wrap_stream_raw vagrant destroy -f

# Validate all expected packages were built
for p in "${!package_list[@]}"; do
    path=(pkg/${p})
    if [ ! -f "${path[0]}" ]; then
        packages_missing="${packages_missing},${p}"
    fi
done
packages_missing="${packages_missing#,}"

# Check if any packages are missing. If so and this is a
# proper Vagrant release, fail hard. Otherwise, emit a warning
# about the missing packages and carry on
if [ "${packages_missing}" != "" ]; then
    if [ -n "${release}" ]; then
        fail "Missing Vagrant package assets matching patterns: ${packages_missing}"
    else
        warn "Missing Vagrant package assets matching patterns: ${packages_missing}"
    fi
fi
