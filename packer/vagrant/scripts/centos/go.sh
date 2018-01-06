#!/bin/sh

uname -m | grep x86_64 > /dev/null

if [ $? -eq 0 ]
then
    ARCH="amd64"
else
    ARCH="386"
fi

wget -O go.tar.gz https://storage.googleapis.com/golang/go1.9.2.linux-${ARCH}.tar.gz
tar -C /usr/local -xzf go.tar.gz

echo "export PATH=$PATH:/usr/local/go/bin" > /etc/profile.d/go-path.sh
echo "export PATH=$PATH:/usr/local/go/bin" >> /home/vagrant/.bash_profile
chmod 755 /etc/profile.d/go-path.sh

ln -s /usr/local/go/bin/go /usr/local/bin/
