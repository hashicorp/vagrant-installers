#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/load-ci.sh"

pushd "${root}"

# Load these after the CI is loaded since it uses
# CI defined variables
. "${root}/.ci/packaging-vars.sh"

# List of all substrate artifacts suffix values and
# the guest name which will generate them
declare -A substrate_list=(
    [*archlinux_x86_64.zip]="archlinux"
    [*centos_x86_64.zip]="centos-6"
    [*centos_i686.zip]="centos-7-i386"
    [*darwin_x86_64.zip]="osx-10.15"
    [*ubuntu_x86_64.zip]="ubuntu-14.04"
    [*ubuntu_i686.zip]="ubuntu-14.04-i386"
    [*windows_x86_64.zip]="win-8"
    [*windows_i686.zip]="win-8"
)

# Create the substrate assets directory if
# it doesn't already exist
mkdir -p substrate-assets

# If we have a substrate identifer defined, attempt to fetch them
if [ -n "${SUBSTRATES_IDENTIFIER}" ]; then
    pushd substrate-assets
    github_draft_release_assets "${repo_owner}" "${repo_name}" "${SUBSTRATES_IDENTIFIER}"
    popd
else
    fail "No identifier defined for substrates"
fi

# Generate a list of substrates we already have (if any)
for p in "${!substrate_list[@]}"; do
    path=(substrate-assets/${p})
    if [ ! -f "${path[0]}" ]; then
        substrates_needed="${substrates_needed},${substrate_list[${p}]}"
    fi
done
substrates_needed="${substrates_needed#,}"

# If all substrates have been built already, we are done
if [ -z "${substrates_needed}" ]; then
    echo "All substrates are currently built"
    exit
fi

# Ensure we are ready for using packet
packet-setup

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
declare -A substrate_builds

# Only start guests for substrates that are needed and
# set our build type to substrate
export PKT_VAGRANT_ONLY_BOXES="${substrates_needed}"
export PKT_VAGRANT_BUILD_TYPE="substrate"

# Begin by starting the guests without provisioning
echo "Starting Vagrant substrate guests..."
pkt_wrap_stream vagrant up --no-provision \
    "Failed to start builder guests on packet device for substrates"

echo "Start Vagrant substrate builds..."

# Load secrets and persist for use.
export PACKET_EXEC_PRE_BUILTINS="LoadSecrets"
packet-exec run -quiet -- sleep 500 &
unset PACKET_EXEC_PRE_BUILTINS
# Include a pause here to allow for everything to
# get properly setup
sleep 10

# Now iterate through each substrate that needs to be built
# and start the provision task on the guest
for p in "${!substrate_list[@]}"; do
    path=(substrate-assets/${p})
    guest="${substrate_list[${p}]}"
    if [ -f "${path[0]}" ] || [ -n "${substrate_builds[${guest}]}" ]; then
        continue
    fi
    echo "Running substrate build for ${guest}..."
    export PKT_VAGRANT_ONLY_BOXES="${guest}"
    packet-exec run -- vagrant provision "${guest}" > "${guest}.log" 2>&1 &
    pid=$!
    substrate_builds["${guest}"]="${pid}"
    until [ -f "${guest}.log" ]; do
        sleep 0.1
    done
    tail -f --quiet --pid "${pid}" "${guest}.log" &
done

# Wait for all the background provisions to complete
# NOTE: We don't check pid success since substrate file check
#       below will catch any errors
for pid in "${substrate_builds[@]}"; do
    wait "${pid}"
done

# Run simple command to pull any built substrates
wrap_stream_raw packet-exec run \
    -download "./substrate-assets/*:./substrate-assets" -- /bin/true

# Stash the substrates in a draft for reuse
draft_release "${SUBSTRATES_IDENTIFIER}" ./substrate-assets

# Now that we have finished, destroy any guests we created
echo "Destroying existing Vagrant guests..."
# Clean up the substrate VMs
unset PKT_VAGRANT_ONLY_BOXES
pkt_wrap_stream_raw vagrant destroy -f

# Validate all expected substrates were built
for p in "${!substrate_list[@]}"; do
    path=(substrate-assets/${p})
    if [ ! -f "${path[0]}" ]; then
        substrates_missing="${substrates_missing},${p}"
    fi
done
substrates_missing="${substrates_missing#,}"

# Check if any substrates are missing. If so and this is a
# proper Vagrant release, fail hard. Otherwise, emit a warning
# about the missing substrates and carry on
if [ "${substrates_missing}" != "" ]; then
    if [ -n "${release}" ]; then
        fail "Missing Vagrant substrate assets matching patterns: ${substrates_missing}"
    else
        warn "Missing Vagrant substrate assets matching patterns: ${substrates_missing}"
    fi
fi
