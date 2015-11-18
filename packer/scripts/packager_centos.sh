#!/bin/bash

# Install development tools because we always need those
yum -y groupinstall 'Development Tools'

# EPEL
wget http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
rpm -Uvh epel-release-5*.rpm

# Install it system-wide
curl -sSL https://get.rvm.io | bash -s stable

# Let this user use it and install Rubies
usermod -a -G rvm `whoami`

# Set the shell for this user
chsh -s /bin/bash `whoami`

# Install Rubies. This must be done by logging the user in to take
# advantage of the group permissions above.
cat <<EOF >/tmp/rvm.sh
#!/bin/bash --login
set -e

# Install the proper Rubies
rvm install 2.2.3
rvm use --default 2.2.3
gem install fpm --no-ri --no-rdoc
EOF
chmod +x /tmp/rvm.sh
su -l -c "/tmp/rvm.sh" `whoami`
