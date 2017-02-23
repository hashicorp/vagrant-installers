#!/bin/sh

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"

gem install json_pure -v '~> 1.0' --no-ri --no-rdoc
gem install puppet -v '~> 3.0' --no-ri --no-rdoc

result=1
attempts=0
while [ "${result}" -ne "0" ]
do
    TRAVIS=1 su vagrant -l -c 'ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install | sed 's%https://github%git://github%g')"'
    result=$?
    attempts=$(expr $attempts + 1)
    if [ $attempts -gt 5 ]
    then
        echo "Failed to install homebrew!"
        exit 1
    else
        sleep 2
    fi
done

mkdir -p /vagrant/substrate-assets
chmod 755 /vagrant/substrate/run.sh

/vagrant/substrate/run.sh /vagrant/substrate-assets
