#!/usr/bin/env bash

export SLACK_USERNAME="Vagrant"
export SLACK_ICON="https://avatars.slack-edge.com/2017-10-17/257000837696_070f98107cdacc0486f6_36.png"
export SLACK_TITLE="Vagrant Packaging"
export PACKET_EXEC_DEVICE_NAME="${PACKET_EXEC_DEVICE_NAME:-ci-installers}"
export PACKET_EXEC_DEVICE_SIZE="${PACKET_EXEC_DEVICE_SIZE:-baremetal_0,baremetal_1,baremetal_1e}"
export PACKET_EXEC_PREFER_FACILITIES="${PACKET_EXEC_PREFER_FACILITIES:-iad1,iad2,ewr1,dfw1,dfw2,sea1,sjc1,lax1}"
export PACKET_EXEC_OPERATING_SYSTEM="${PACKET_EXEC_OPERATING_SYSTEM:-ubuntu_18_04}"
export PACKET_EXEC_PRE_BUILTINS="${PACKET_EXEC_PRE_BUILTINS:-InstallVmware,InstallVagrant,InstallVagrantVmware}"
export PACKET_EXEC_ATTACH_VOLUME="1"
export PACKET_EXEC_QUIET="1"
export PKT_VAGRANT_HOME="/mnt/data"
export PKT_VAGRANT_CLOUD_TOKEN="${VAGRANT_CLOUD_TOKEN}"

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/common.sh"

pushd "${root}" > "${output}"

# Define a custom cleanup function to destroy any orphan guests
# on the packet instance
function cleanup() {
    unset PACKET_EXEC_PERSIST
    packet-exec run -- pkill -f vmware-vmx
}

trap cleanup EXIT

# Set variables we'll need later
declare -A substrate_list=(
    [*centos_x86_64.zip]="centos-6"
    [*centos_i686.zip]="centos-6-i386"
    [*darwin_x86_64.zip]="osx-10.15"
    [*ubuntu_x86_64.zip]="ubuntu-14.04"
    [*ubuntu_i686.zip]="ubuntu-14.04-i386"
    [*windows_x86_64.zip]="win-7"
    [*windows_i686.zip]="win-7"
)

declare -A package_list=(
    [*amd64.zip]="appimage"
#    [*x86_64.tar.xz]="archlinux"
    [*x86_64.rpm]="centos-6"
    [*i686.rpm]="centos-6-i386"
    [*x86_64.dmg]="osx-10.15"
    [*x86_64.deb]="ubuntu-14.04"
    [*i686.deb]="ubuntu-14.04-i386"
    [*x86_64.msi]="win-7"
    [*i686.msi]="win-7"
)

s3_substrate_dst="${ASSETS_PRIVATE_LONGTERM}/${repository}/${short_sha}"
if [ "${tag}" != "" ]; then
    if [[ "${tag}" = *"+"* ]]; then
        s3_package_dst="${ASSETS_PRIVATE_LONGTERM}/${repository}/${tag}"
    else
        s3_package_dst="${ASSETS_PRIVATE_BUCKET}/${repository}/${tag}"
    fi
else
    s3_package_dst="${ASSETS_PRIVATE_LONGTERM}/${repository}/${ident_ref}/${short_sha}"
fi
job_id=$(uuidgen)
export PACKET_EXEC_REMOTE_DIRECTORY="${job_id}"
export PACKET_EXEC_PERSIST="1"
export PKT_VAGRANT_INSTALLERS_VAGRANT_PACKAGE_SIGNING_REQUIRED=1

# Grab the vagrant gem the installer is building around
echo "Fetching Vagrant RubyGem for installer build..."

if [ "${tag}" = "" ]; then
    wrap aws s3 cp ${ASSETS_PRIVATE_BUCKET}/${repo_owner}/vagrant/vagrant-master.gem vagrant-master.gem \
         "Failed to download Vagrant RubyGem"
else
    url=$(curl -SsL -H "Authorization: token ${HASHIBOT_TOKEN}" -H "Content-Type: application/json" "https://api.github.com/repos/${repository}/releases/tags/${tag}" | jq -r '.assets[] | select(.name | contains(".gem")) | .url')
    wrap curl -H "Authorization: token ${HASHIBOT_TOKEN}" -H "Accept: application/octet-stream" -SsL -o "vagrant-${tag}.gem" "${url}" \
         "Failed to download Vagrant RubyGem"
fi

# Extract out Vagrant version information from gem
vagrant_version="$(gem specification vagrant-*.gem version)"
vagrant_version="${vagrant_version##*version: }"

# Place gem into package directory for packaging
wrap mv vagrant-*.gem package/vagrant.gem \
     "Failed to move vagrant RubyGem for packaging"

# Ensure we have a packet device to connect
echo "Creating packet device if needed..."

packet-exec info

if [ $? -ne 0 ]; then
    wrap_stream packet-exec create \
                "Failed to create packet device"
fi

# Build our substrates
mkdir -p substrate-assets pkg

echo "Fetching any prebuilt substrates and/or packages... "

# If there are existing substrates or packages already built, download them
aws s3 sync --no-progress "${s3_substrate_dst}/" ./substrate-assets/ > "${output}" 2>&1
aws s3 sync --no-progress "${s3_package_dst}/" ./pkg/ > "${output}" 2>&1

# Make signing files available before upload
secrets=$(load-signing) || fail "Failed to load signing files"
eval "${secrets}"

echo "Setting up remote packet device for current job... "
# NOTE: We only need to call packet-exec with the -upload option once
#       since we are persisting the job directory. This dummy command
#       is used simply to seed the work directory.
wrap_stream packet-exec run -upload -- /bin/true \
            "Failed to setup project on remote packet instance"

for p in "${!substrate_list[@]}"; do
    path=(substrate-assets/${p})
    if [ ! -f "${path}" ]; then
        substrates_needed="${substrates_needed},${substrate_list[${p}]}"
    fi
done
substrates_needed="${substrates_needed#,}"

if [ "${substrates_needed}" = "" ]; then
    echo "All substrates currently exist. No build required."
else

    export PKT_VAGRANT_ONLY_BOXES="${substrates_needed}"
    export PKT_VAGRANT_BUILD_TYPE="substrate"

    echo "Starting Vagrant substrate guests..."
    pkt_wrap_stream vagrant up --no-provision \
                    "Failed to start builder guests on packet device for substrates"
    echo "Start Vagrant substrate builds..."

    pids=()
    for p in "${!substrate_list[@]}"; do
        path=(substrate-assets/${p})
        if [ -f "${path}" ]; then
            continue
        fi
        guest="${substrate_list[${p}]}"
        export PKT_VAGRANT_ONLY_BOXES="${guest}"
        packet-exec run -- vagrant provision "${guest}" > "${guest}.log" 2>&1 &
        pid=$!
        until [ -f "${guest}.log" ]; do
            sleep 0.1
        done
        tail -f --quiet --pid "${pid}" "${guest}.log" &
        pids+=("${pid}")
    done

    # Wait for all the background provisions to complete
    # NOTE: We don't check pid success since substrate file check
    #       below will catch any errors
    for pid in "${pids[@]}"; do
        wait "${pid}"
    done

    # Run simple command to pull any built substrates
    wrap_stream_raw packet-exec run -download "./substrate-assets/*:./substrate-assets" -- /bin/true

    echo "Storing any built substrates... "
    # Store all built substrates
    wrap_stream_raw aws s3 sync --no-progress ./substrate-assets/ "${s3_substrate_dst}"

    echo "Destroying existing Vagrant guests..."
    # Clean up the substrate VMs
    unset PKT_VAGRANT_ONLY_BOXES
    pkt_wrap_stream_raw vagrant destroy -f
fi

# Validate all substrates are available
for p in "${!substrate_list[@]}"; do
    path=(substrate-assets/${p})
    if [ ! -f "${path}" ]; then
        fail "Missing expected substrate at '${path}'"
    fi
done


for p in "${!package_list[@]}"; do
    path=(pkg/${p})
    if [ ! -f "${path}" ]; then
        packages_needed="${packages_needed},${package_list[${p}]}"
    fi
done
packages_needed="${packages_needed#,}"

if [ "${packages_needed}" = "" ]; then
    echo "All packages currently exist. No build required."
else
    export PKT_VAGRANT_ONLY_BOXES="${packages_needed}"
    export PKT_VAGRANT_BUILD_TYPE="package"

    if [ ! -z "${release}" ]; then
        export PKT_VAGRANT_INSTALLER_VAGRANT_PACKAGE_SIGNING_REQUIRED="1"
    fi

    echo "Starting Vagrant package guests... "
    pkt_wrap_stream vagrant up --no-provision \
                    "Failed to start builder guests on packet device for packaging"
    echo "Start Vagrant package builds..."

    export PACKET_EXEC_PRE_BUILTINS="LoadSecrets"

    pids=()
    for p in "${!package_list[@]}"; do
        path=(pkg/${p})
        if [ -f "${path}" ]; then
            continue
        fi
        guest="${package_list[${p}]}"
        export PKT_VAGRANT_ONLY_BOXES="${guest}"
        packet-exec run -- vagrant provision "${guest}" > "${guest}.log" 2>&1 &
        pid=$!
        until [ -f "${guest}.log" ]; do
            sleep 0.1
        done
        tail -f --quiet --pid "${pid}" "${guest}.log" &
        pids+=("${pid}")
    done

    unset PACKET_EXEC_PRE_BUILTINS

    # Wait for all the background provisions to complete
    for pid in "${pids[@]}"; do
        wait "${pid}"
    done

    # Fetch any built packages
    wrap_stream_raw packet-exec run -download "./pkg/*:./pkg" -- /bin/true

    # Store all built packages
    echo "Storing any built packages... "
    wrap_stream_raw aws s3 sync --no-progress ./pkg/ "${s3_package_dst}"

    echo "Destroying existing Vagrant guests..."
    unset PKT_VAGRANT_ONLY_BOXES
    pkt_wrap_stream_raw vagrant destroy -f
fi

# Validate all expected packages were built
for p in "${!package_list[@]}"; do
    path=(pkg/${p})
    if [ ! -f "${path}" ]; then
        packages_missing="${packages_missing},${p}"
    fi
done
packages_missing="${packages_missing#,}"

if [ "${packages_missing}" != "" ]; then
    fail "Missing Vagrant package assets matching patterns: ${packages_missing}"
fi

# If this is a release build sign our package assets and then upload
# via the hc-releases binary
if [ ! -z "${release}" ]; then
    echo -n "Cloning Vagrant repository for signing process... "
    wrap git clone git://github.com/hashicorp/vagrant vagrant \
         "Failed to clone Vagrant repository"

    mkdir -p vagrant/pkg/dist
    mv pkg/* vagrant/pkg/dist/
    pushd vagrant > "${output}"

    echo "Generating checksums and signing result for Vagrant version ${vagrant_version}..."
    export PACKET_EXEC_PRE_BUILTINS="LoadSecrets"
    wrap_stream packet-exec run -upload -download "./pkg/dist/*SHA256SUMS*:./pkg/dist" -- ./scripts/sign.sh "${vagrant_version}" \
                "Checksum generation and signing failed for release"
    unset PACKET_EXEC_PRE_BUILTINS
    popd > "${output}"

    mv vagrant/pkg/dist/* pkg/

    echo "Storing release packages into asset store..."
    upload_assets pkg/

    # TODO: Remove after first successful run
    slack -m  "New Vagrant release is ready for upload! - v${vagrant_version}\n\nAssets: $(asset_location)"
    exit

    echo "Releasing new version of Vagrant to HashiCorp releases - v${vagrant_version}"
    hashicorp_release pkg/

    slack -m "New Vagrant release has been published! - *${vagrant_version}*\n\nAssets: https://releases.hashicorp.com/vagrant/${vagrant_version}\nStore: $(asset_location)"
else
    if [ "${tag}" != "" ]; then
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

    slack -m "New Vagrant development installers available:\n> https://github.com/${respository}/releases/${prerelease_version}"
fi
