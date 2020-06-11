#!/usr/bin/env bash

export SLACK_USERNAME="Vagrant"
export SLACK_ICON="https://avatars.slack-edge.com/2017-10-17/257000837696_070f98107cdacc0486f6_36.png"
export SLACK_TITLE="Vagrant Builder Boxes"
export PACKET_EXEC_DEVICE_NAME="${PACKET_EXEC_DEVICE_NAME:-ci-installer-boxes}"
export PACKET_EXEC_DEVICE_SIZE="${PACKET_EXEC_DEVICE_SIZE:-baremetal_0,baremetal_1,baremetal_1e}"
export PACKET_EXEC_PREFER_FACILITIES="${PACKET_EXEC_PREFER_FACILITIES:-iad1,iad2,ewr1,dfw1,dfw2,sea1,sjc1,lax1}"
export PACKET_EXEC_OPERATING_SYSTEM="${PACKET_EXEC_OPERATING_SYSTEM:-ubuntu_18_04}"
export PACKET_EXEC_PRE_BUILTINS="${PACKET_EXEC_PRE_BUILTINS:-InstallVmware,InstallVagrant,InstallVagrantVmware,InstallHashiCorpTool}"
export PACKET_EXEC_QUIET="1"
export PKT_VAGRANT_HOME="/mnt/data"
export PKT_VAGRANT_CLOUD_TOKEN="${VAGRANT_CLOUD_TOKEN}"
export PKT_HASHICORP_TOOL="packer"
export PKT_HASHICORP_TOOL_VERSION="1.5.4"
export PKT_SLACK_TOKEN="${SLACK_TOKEN}"
export PKT_SLACK_USERNAME="${SLACK_USERNAME}"
export PKT_SLACK_ICON="${SLACK_ICON}"
export PKT_SLACK_TITLE="${SLACK_TITLE}"

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/common.sh"

pushd "${root}" > "${output}"

export PKT_PACKER_BUILDS="${PKT_PACKER_BUILDS:-centos-6,centos-6-i386,ubuntu-14.04,ubuntu-14.04-i386,win-8}"
export PACKET_EXEC_REMOTE_DIRECTORY="${job_id}"

# Ensure we have a packet device to connect
echo "Creating packet device if needed..."

packet-exec info

if [ $? -ne 0 ]; then
    wrap_stream packet-exec create \
                "Failed to create packet device"
fi

# Starting box build job on packet-exec device
wrap_stream packet-exec run -upload -- ./.ci/boxes.sh \
            "Failed to setup project on remote packet instance"
