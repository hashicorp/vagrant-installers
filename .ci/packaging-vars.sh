#!/usr/bin/env bash

export SLACK_USERNAME="Vagrant"
export SLACK_ICON="https://avatars.slack-edge.com/2017-10-17/257000837696_070f98107cdacc0486f6_36.png"
export SLACK_TITLE="Vagrant Packaging"
export PACKET_EXEC_DEVICE_NAME="${PACKET_EXEC_DEVICE_NAME:-ci-installers-${run_id}}"
export PACKET_EXEC_DEVICE_SIZE="${PACKET_EXEC_DEVICE_SIZE:-c3.small.x86,m3.small.x86}"
export PACKET_EXEC_PREFER_FACILITIES="${PACKET_EXEC_PREFER_FACILITIES:-da6,sv15,sv16,da11,ch3,dc10,dc13,ny5,ny7}"
export PACKET_EXEC_OPERATING_SYSTEM="${PACKET_EXEC_OPERATING_SYSTEM:-ubuntu_18_04}"
export PACKET_EXEC_PRE_BUILTINS="${PACKET_EXEC_PRE_BUILTINS:-InstallVmware,InstallVagrant,InstallVagrantVmware}"
export PACKET_EXEC_QUIET="1"
export PACKET_EXEC_REMOTE_DIRECTORY="${job_id}${GITHUB_JOB}"
export PACKET_EXEC_PERSIST="1"
export PKT_WORKSTATION_DOWNLOAD_URL="https://vagrant-public-cache.s3.amazonaws.com/VMware-Workstation-Full-15.5.6-16341506.x86_64.bundle"
export PKT_VAGRANT_INSTALLERS_VAGRANT_PACKAGE_SIGNING_REQUIRED=1
export PKT_VAGRANT_HOME="/mnt/data"
export PKT_VAGRANT_CLOUD_TOKEN="${VAGRANT_CLOUD_TOKEN}"
