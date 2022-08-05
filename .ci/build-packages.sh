#!/usr/bin/env bash

export SLACK_USERNAME="Vagrant"
export SLACK_ICON="https://avatars.slack-edge.com/2017-10-17/257000837696_070f98107cdacc0486f6_36.png"
export SLACK_TITLE="Vagrant Packaging"
export PACKET_EXEC_DEVICE_NAME="${PACKET_EXEC_DEVICE_NAME:-ci-installers}"
export PACKET_EXEC_DEVICE_SIZE="${PACKET_EXEC_DEVICE_SIZE:-c3.small.x86,m3.small.x86}"
export PACKET_EXEC_PREFER_FACILITIES="${PACKET_EXEC_PREFER_FACILITIES:-da6,sv15,sv16,da11,ch3,dc10,dc13,ny5,ny7}"
export PACKET_EXEC_OPERATING_SYSTEM="${PACKET_EXEC_OPERATING_SYSTEM:-ubuntu_18_04}"
export PACKET_EXEC_PRE_BUILTINS="${PACKET_EXEC_PRE_BUILTINS:-InstallVmware,InstallVagrant,InstallVagrantVmware}"
export PACKET_EXEC_ATTACH_VOLUME="1"
export PACKET_EXEC_VOLUME_SIZE="200"
export PACKET_EXEC_QUIET="1"
export PKT_VAGRANT_HOME="/mnt/data"
export PKT_VAGRANT_CLOUD_TOKEN="${VAGRANT_CLOUD_TOKEN}"

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/load-ci.sh"

pushd "${root}" > "${output}"

if [ ! -z "${release}" ]; then
    export SLACK_CHANNEL="#team-vagrant"
    slack -m "Starting Vagrant release build for: ${tag}"
else
    export SLACK_CHANNEL="#team-vagrant-spam-channel"
fi

# Grab a recent cacert bundle
curl -O https://curl.se/ca/cacert.pem

# Define a custom cleanup function to destroy any orphan guests
# on the packet instance
function cleanup() {
    unset PACKET_EXEC_PERSIST
    packet-exec run -- pkill -f vmware-vmx
}

trap cleanup EXIT

# Set variables we'll need later
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

declare -A package_list=(
    [*amd64.zip]="appimage"
    [*x86_64.tar.zst]="archlinux"
    [*x86_64.rpm]="centos-6"
    [*i686.rpm]="centos-7-i386"
    [*x86_64.dmg]="osx-10.15"
    [*x86_64.deb]="ubuntu-14.04"
    [*i686.deb]="ubuntu-14.04-i386"
    [*x86_64.msi]="win-8"
    [*i686.msi]="win-8"
)

# Grab the vagrant gem and vagrant-agogo the installer is building around
echo "Fetching Vagrant RubyGem and binaries for installer build..."

if [ "${tag}" = "" ]; then
    wrap aws s3 cp "${ASSETS_PRIVATE_BUCKET}/${repo_owner}/vagrant/vagrant-main.gem" vagrant-main.gem \
         "Failed to download Vagrant RubyGem"
    wrap aws s3 cp "${ASSETS_PRIVATE_BUCKET}/${repo_owner}/vagrant/vagrant-go_main_linux_amd64.zip" vagrant_linux64.zip \
        "Failed to download Vagrant go linux amd64 binary"
    wrap aws s3 cp "${ASSETS_PRIVATE_BUCKET}/${repo_owner}/vagrant/vagrant-go_main_linux_386.zip" vagrant_linux32.zip \
        "Failed to download Vagrant go linux 386 binary"
    wrap aws s3 cp "${ASSETS_PRIVATE_BUCKET}/${repo_owner}/vagrant/vagrant-go_main_darwin_amd64.zip" vagrant_darwin64.zip \
        "Failed to download Vagrant go darwin amd64 binary"
else
    url_gem=$(curl -SsL -H "Authorization: token ${HASHIBOT_TOKEN}" -H "Content-Type: application/json" "https://api.github.com/repos/${repository}/releases/tags/${tag}" | jq -r '.assets[] | select(.name | contains(".gem")) | .url')
    url_linux64_zip=$(curl -SsL -H "Authorization: token ${HASHIBOT_TOKEN}" -H "Content-Type: application/json" "https://api.github.com/repos/${repository}/releases/tags/${tag}" | jq -r '.assets[] | select(.name | contains("linux_amd64.zip")) | .url')
    url_linux32_zip=$(curl -SsL -H "Authorization: token ${HASHIBOT_TOKEN}" -H "Content-Type: application/json" "https://api.github.com/repos/${repository}/releases/tags/${tag}" | jq -r '.assets[] | select(.name | contains("linux_386.zip")) | .url')
    url_darwin64_zip=$(curl -SsL -H "Authorization: token ${HASHIBOT_TOKEN}" -H "Content-Type: application/json" "https://api.github.com/repos/${repository}/releases/tags/${tag}" | jq -r '.assets[] | select(.name | contains("darwin_386.zip")) | .url')
    wrap curl -H "Authorization: token ${HASHIBOT_TOKEN}" -H "Accept: application/octet-stream" -SsL -o "vagrant-${tag}.gem" "${url_gem}" \
         "Failed to download Vagrant RubyGem"
    wrap curl -H "Authorization: token ${HASHIBOT_TOKEN}" -H "Accept: application/octet-stream" -SsL -o "vagrant_linux64.zip" "${url_linux64_zip}" \
         "Failed to download Vagrant go linux amd64 zip"
    wrap curl -H "Authorization: token ${HASHIBOT_TOKEN}" -H "Accept: application/octet-stream" -SsL -o "vagrant_linux32.zip" "${url_linux32_zip}" \
         "Failed to download Vagrant go linux 386 zip"
    wrap curl -H "Authorization: token ${HASHIBOT_TOKEN}" -H "Accept: application/octet-stream" -SsL -o "vagrant_darwin64.zip" "${url_darwin64_zip}" \
         "Failed to download Vagrant go darwin amd64 zip"
fi

gem_short_sha=$(sha256sum vagrant-*.gem)

s3_substrate_dst="${ASSETS_PRIVATE_LONGTERM}/${repository}/${short_sha}"
if [ "${tag}" != "" ]; then
    if [[ "${tag}" = *"+"* ]]; then
        s3_package_dst="${ASSETS_PRIVATE_LONGTERM}/${repository}/${tag}"
    else
        s3_package_dst="${ASSETS_PRIVATE_BUCKET}/${repository}/${tag}-${gem_short_sha}"
    fi
else
    s3_package_dst="${ASSETS_PRIVATE_LONGTERM}/${repository}/${ident_ref}/${short_sha}-${gem_short_sha}"
fi

export PACKET_EXEC_REMOTE_DIRECTORY="${job_id}"
export PACKET_EXEC_PERSIST="1"
export PKT_VAGRANT_INSTALLERS_VAGRANT_PACKAGE_SIGNING_REQUIRED=1

# Extract out Vagrant version information from gem
vagrant_version="$(gem specification vagrant-*.gem version)"
vagrant_version="${vagrant_version##*version: }"

# Decompress the go binaries
wrap unzip vagrant_linux64.zip \
    "Failed to unzip Vagrant go linux amd64 asset"
wrap unzip vagrant_linux32.zip \
    "Failed to unzip Vagrant go linux 386 asset"
wrap unzip vagrant_darwin64.zip \
    "Failed to unzip Vagrant go darwin amd64 asset"

# Remove the compressed assets
rm -f vagrant_*.zip

# Place gem into package directory for packaging
wrap cp vagrant-*.gem package/vagrant.gem \
     "Failed to move vagrant RubyGem for packaging"

# Place the go binary into the package directory for packaging
wrap cp vagrant-go_* package/ \
     "Failed to move vagrant go binary for packaging"

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

# force renewal of the aws session
AWS_SESSION_EXPIRATION=$(date)
# If there are existing substrates or packages already built, download them
aws s3 sync --no-progress "${s3_substrate_dst}/" ./substrate-assets/
aws s3 sync --no-progress "${s3_package_dst}/" ./pkg/

# Make signing files available before upload
secrets=$(load-signing) || fail "Failed to load signing files"
eval "${secrets}"

echo "Setting up remote packet device for current job... "
# NOTE: We only need to call packet-exec with the -upload option once
#       since we are persisting the job directory. This dummy command
#       is used simply to seed the work directory.
wrap_stream packet-exec run -upload -- /bin/true \
            "Failed to setup project on remote packet instance"

# Always ensure boxes are up to date
pkt_wrap_stream vagrant box update \
                "Failed to update local build boxes"

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
    declare -A substrate_builds

    export PKT_VAGRANT_ONLY_BOXES="${substrates_needed}"
    export PKT_VAGRANT_BUILD_TYPE="substrate"

    echo "Starting Vagrant substrate guests..."
    pkt_wrap_stream vagrant up --no-provision \
                    "Failed to start builder guests on packet device for substrates"
    echo "Start Vagrant substrate builds..."

    # Load secrets and persist for use
    export PACKET_EXEC_PRE_BUILTINS="LoadSecrets"
    packet-exec run -quiet -- sleep 500 &
    unset PACKET_EXEC_PRE_BUILTINS

    echo "Pausing to allow secrets to become available"
    sleep 10
    echo "Resuming after secrets pause"

    for p in "${!substrate_list[@]}"; do
        path=(substrate-assets/${p})
        guest="${substrate_list[${p}]}"
        if [ -f "${path}" ] || [ ! -z "${substrate_builds[${guest}]}" ]; then
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
    wrap_stream_raw packet-exec run -download "./substrate-assets/*:./substrate-assets" -- /bin/true

    echo "Storing any built substrates... "
    # force renewal of the aws session
    AWS_SESSION_EXPIRATION=$(date)
    # Store all built substrates
    wrap_stream_raw aws s3 sync --no-progress ./substrate-assets/ "${s3_substrate_dst}"

    echo "Destroying existing Vagrant guests..."
    # Clean up the substrate VMs
    unset PKT_VAGRANT_ONLY_BOXES
    pkt_wrap_stream_raw vagrant destroy -f
fi

# Validate all expected substrates were built
for p in "${!substrate_list[@]}"; do
    path=(substrate-assets/${p})
    if [ ! -f "${path}" ]; then
        substrates_missing="${substrates_missing},${p}"
    fi
done
substrates_missing="${substrates_missing#,}"

if [ "${substrates_missing}" != "" ]; then
    if [ -n "${release}" ]; then
        fail "Missing Vagrant substrate assets matching patterns: ${substrates_missing}"
    else
        warn "Missing Vagrant substrate assets matching patterns: ${substrates_missing}"
    fi
fi


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
    declare -A package_builds

    export PKT_VAGRANT_ONLY_BOXES="${packages_needed}"
    export PKT_VAGRANT_BUILD_TYPE="package"

    if [ ! -z "${release}" ]; then
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

    echo "Pausing to allow secrets to become available"
    sleep 10
    echo "Resuming after secrets pause"

    for p in "${!package_list[@]}"; do
        path=(pkg/${p})
        guest="${package_list[${p}]}"
        if [ -f "${path}" ] || [ ! -z "${package_builds[${guest}]}" ]; then
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
        unset PACKET_EXEC_PRE_BUILTINS
    done

    # Wait for all the background provisions to complete
    for pid in "${package_builds[@]}"; do
        wait "${pid}"
    done

    # Fetch any built packages
    wrap_stream_raw packet-exec run -download "./pkg/*:./pkg" -- /bin/true

    # force renewal of the aws session
    AWS_SESSION_EXPIRATION=$(date)
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
    if [ -n "${release}" ]; then
        fail "Missing Vagrant package assets matching patterns: ${packages_missing}"
    else
        warn "Missing Vagrant package assets matching patterns: ${packages_missing}"
    fi
fi

# If this is not a release build, push the prerelease to GitHub
if [ -z "${release}" ]; then
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

    slack -m "New Vagrant development installers available:\n> https://github.com/${repository}/releases/${prerelease_version}"

    echo "Dispatching vagrant-acceptance"
    curl -X POST "https://api.github.com/repos/hashicorp/vagrant-acceptance/dispatches" \
         -H 'Accept: application/vnd.github.everest-v3+json' \
         -u $HASHIBOT_USERNAME:$HASHIBOT_TOKEN \
         --data '{"event_type": "prerelease", "client_payload": { "prerelease_version": "'"${prerelease_version}"'"}}'

    # As this is not an actual release, we are done now
    exit
fi

# If we are still here, then this is a release build. Sign the
# assets and publish the release.
echo -n "Cloning Vagrant repository for signing process... "
wrap git clone https://${HASHIBOT_USERNAME}:${HASHIBOT_TOKEN}@github.com/hashicorp/vagrant vagrant \
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

echo "Releasing new version of Vagrant to HashiCorp releases - v${vagrant_version}"
hashicorp_release pkg/ vagrant

slack -m "New Vagrant release has been published! - *${vagrant_version}*\n\nAssets: https://releases.hashicorp.com/vagrant/${vagrant_version}\nStore: $(asset_location)"

# Now that we have published the new version we need to create
# a new branch for the versioned docs and push the gem as a release
# into the vagrant repository.
tags=($(git tag -l --sort=v:refname)) # this provides tag list in ascending order
tag_len="${#tags[@]}"
for ((i=0; i < "${tag_len}"; i++))
do
    val=$(semver "${vagrant_version}" "${tag}")
    if [[ "${val}" == "0" ]]; then
        idx=$((i+1))
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
echo "Creating a new release-${previous_version} branch..."

wrap git checkout stable-website \
     "Failed to checkout stable-website branch"
wrap git checkout -b "${release_branch}" \
     "Failed to create new branch: ${release_branch}"
wrap git push origin "${release_branch}" \
     "Failed to push new branch: ${release_branch}"

echo "Creating a new ${release_minor_branch} branch..."
wrap git checkout stable-website \
     "Failed to checkout stable-website branch"
git branch -d "${release_minor_branch}" > "${output}"

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
     "Failed to delete stable-website branch"
wrap git checkout -b stable-website \
     "Failed to create new stable-website branch from release v${vagrant_version}"
wrap git push -f origin stable-website \
     "Failed to push updated stable-website branch"

slack -m "Vagrant website changes have been pushed for release ${vagrant_version}"

# Finally, we need to create a release on the vagrant repository
wrap mv ../"vagrant-${vagrant_version}.gem" ./

# Override local variables to create release on vagrant repository
repo_owner="hashicorp"
repo_name="vagrant"
full_sha="v${vagrant_version}"
export GITHUB_TOKEN="${HASHIBOT_TOKEN}"

release "v${vagrant_version}" ./"vagrant-${vagrant_version}.gem"

slack -m "New Vagrant GitHub release created for v${vagrant_release} - release process complete."
