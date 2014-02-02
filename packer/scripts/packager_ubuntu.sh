#!/bin/bash
set -e

# Install development tools because we always need those
apt-get -y update
apt-get -y install build-essential

# Install it system-wide
curl -sSL https://get.rvm.io | bash -s stable

# Let this user use it and install Rubies
usermod -a -G rvm `whoami`

# Set the shell for the bamboo user
chsh -s /bin/bash `whoami`

# Install Rubies. This must be done by logging the user in to take
# advantage of the group permissions above.
cat <<EOF >/tmp/rvm.sh
#!/bin/bash --login
set -e

# Install the proper Rubies
rvm install 2.0.0
rvm use --default 2.0.0
gem install fpm --no-ri --no-rdoc
EOF
chmod +x /tmp/rvm.sh
su -l -c "/tmp/rvm.sh" `whoami`
