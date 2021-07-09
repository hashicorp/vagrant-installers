#!/usr/bin/env bash

export SLACK_USERNAME="Vagrant"
export SLACK_ICON="https://avatars.slack-edge.com/2017-10-17/257000837696_070f98107cdacc0486f6_36.png"
export SLACK_TITLE="Vagrant Builder Boxes"
export PACKET_EXEC_DEVICE_NAME="${PACKET_EXEC_DEVICE_NAME:-ci-installer-boxes}"
export PACKET_EXEC_DEVICE_SIZE="${PACKET_EXEC_DEVICE_SIZE:-baremetal_0,baremetal_1,baremetal_1e}"
export PACKET_EXEC_PREFER_FACILITIES="${PACKET_EXEC_PREFER_FACILITIES:-iad2,dfw2,dfw1,ny5,ny7,ewr1,la4,lax1,lax2,tr2,ch3,ord1,ord4}"
export PACKET_EXEC_OPERATING_SYSTEM="${PACKET_EXEC_OPERATING_SYSTEM:-ubuntu_18_04}"
# set workstation url to point to v15. ref: https://github.com/hashicorp/packer/issues/10009
export PKT_WORKSTATION_DOWNLOAD_URL="https://download3.vmware.com/software/wkst/file/VMware-Workstation-Full-15.5.6-16341506.x86_64.bundle"
export PACKET_EXEC_PRE_BUILTINS="${PACKET_EXEC_PRE_BUILTINS:-InstallVmware,InstallVagrant,InstallVagrantVmware,InstallHashiCorpTool}"
export PACKET_EXEC_ATTACH_VOLUME="1"
export PACKET_EXEC_QUIET="1"
export PKT_VAGRANT_HOME="/mnt/data"
export PKT_VAGRANT_CLOUD_TOKEN="${VAGRANT_CLOUD_TOKEN}"
export PKT_HASHICORP_TOOL="packer"
export PKT_SLACK_TOKEN="${SLACK_TOKEN}"
export PKT_SLACK_USERNAME="${SLACK_USERNAME}"
export PKT_SLACK_ICON="${SLACK_ICON}"
export PKT_SLACK_TITLE="${SLACK_TITLE}"
export PKT_PACKER_CACHE_DIR="/mnt/data/packer-cache-dir"

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/load-ci.sh"

pushd "${root}" > "${output}"

function cleanup() {
    unset PACKET_EXEC_PERSIST
    packet-exec run -- /bin/true
}

export PKT_PACKER_BUILDS="${PKT_PACKER_BUILDS:-centos-6,centos-6-i386,ubuntu-14.04,ubuntu-14.04-i386,win-8}"
export PACKET_EXEC_REMOTE_DIRECTORY="${job_id}"

# Ensure we have a packet device to connect
echo "Creating packet device if needed..."

packet-exec info

if [ $? -ne 0 ]; then
    wrap_stream packet-exec create \
                "Failed to create packet device"
fi

# Move into the packer template folder
pushd packer/vagrant > "${output}"

# Force our directory to be uploaded and persisted
export PACKET_EXEC_PERSIST=1
packet-exec run -upload -- /bin/true

IFS=',' read -r -a builds <<< "${PKT_PACKER_BUILDS}"
for build in "${builds[@]}"; do
    echo "Building box for ${build}..."
    export PKT_PACKER_BOX="${build}"
    pkt_wrap_stream packer build -force "template_${build}.json" \
                    "Failed to build box '${build}'"
    slack -m "New Vagrant installers build box available for: ${build}"
done
