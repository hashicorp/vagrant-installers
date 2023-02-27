#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


DEBIAN_FRONTEND=noninteractive apt-add-repository -y ppa:brightbox/ruby-ng
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -qy ruby2.6 ruby2.6-dev build-essential zip unzip

update-alternatives --remove ruby /usr/bin/ruby2.6
update-alternatives --remove irb /usr/bin/irb2.6
update-alternatives --remove gem /usr/bin/gem2.6

update-alternatives \
     --install /usr/bin/ruby ruby /usr/bin/ruby2.6 50 \
     --slave /usr/bin/irb irb /usr/bin/irb2.6 \
     --slave /usr/bin/rake rake /usr/bin/rake2.6 \
     --slave /usr/bin/gem gem /usr/bin/gem2.6 \
     --slave /usr/bin/rdoc rdoc /usr/bin/rdoc2.6 \
     --slave /usr/bin/testrb testrb /usr/bin/testrb2.6 \
     --slave /usr/bin/erb erb /usr/bin/erb2.6 \
     --slave /usr/bin/ri ri /usr/bin/ri2.6

update-alternatives --config ruby
