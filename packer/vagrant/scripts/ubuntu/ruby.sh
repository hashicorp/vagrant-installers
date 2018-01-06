#!/bin/bash

DEBIAN_FRONTEND=noninteractive apt-add-repository -y ppa:brightbox/ruby-ng
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -qy ruby2.4 ruby2.4-dev build-essential zip unzip

update-alternatives --remove ruby /usr/bin/ruby2.4
update-alternatives --remove irb /usr/bin/irb2.4
update-alternatives --remove gem /usr/bin/gem2.4

update-alternatives \
     --install /usr/bin/ruby ruby /usr/bin/ruby2.4 50 \
     --slave /usr/bin/irb irb /usr/bin/irb2.4 \
     --slave /usr/bin/rake rake /usr/bin/rake2.4 \
     --slave /usr/bin/gem gem /usr/bin/gem2.4 \
     --slave /usr/bin/rdoc rdoc /usr/bin/rdoc2.4 \
     --slave /usr/bin/testrb testrb /usr/bin/testrb2.4 \
     --slave /usr/bin/erb erb /usr/bin/erb2.4 \
     --slave /usr/bin/ri ri /usr/bin/ri2.4

update-alternatives --config ruby
