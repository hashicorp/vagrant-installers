#!/bin/bash -eux
echo "==> Applying updates"
yum -y update

# reboot
echo "Rebooting the machine..."
reboot
sleep 60
