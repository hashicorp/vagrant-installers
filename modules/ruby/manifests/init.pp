# == Class: ruby
#
# This installs Ruby from a binary or system package.
#
class ruby {
  case $kernel {
    'Darwin': { include ruby::binary::darwin }
    'Linux' : { include ruby::binary::linux }
    default: { fail("Unknown kernel to install Ruby on.") }
  }
}
