#! /usr/bin/env sh
set -e

# Install development tools because we always need those
pkg update
pkg install -y curl
pkg install -y gcc
pkg install -y bash

# Ensure that /dev/fd is mounted (required by bash)
grep '/dev/fd\>' /etc/fstab > /dev/null || \
  echo 'fdesc   /dev/fd         fdescfs         rw      0       0' >> /etc/fstab
mount | grep '/dev/fd\>' > /dev/null || \
  mount /dev/fd

# Install it system-wide
curl -sSL https://get.rvm.io | bash -s stable

# Let this user use it and install Rubies
pw groupmod rvm -M `whoami`

# Set the shell for the bamboo user
chsh -s `which bash` `whoami`

# Apply changes to our current session
su -l `whoami` -c "source /etc/profile.d/rvm.sh"

# Install Rubies. This must be done by logging the user in to take
# advantage of the group permissions above.
cat <<EOF >/tmp/rvm.sh
#! /usr/bin/env -S bash --login
set -e

# Install the proper Rubies
rvm install 2.2.3
rvm --default use 2.2.3
gem install fpm --no-ri --no-rdoc
EOF
chmod +x /tmp/rvm.sh
su -l `whoami` -c "/tmp/rvm.sh"
