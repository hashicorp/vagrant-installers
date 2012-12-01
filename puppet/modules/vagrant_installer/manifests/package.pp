# == Class: vagrant_installer::package
#
# This makes the installer package for Vagrant.
#
class vagrant_installer::package {
  case $operatingsystem {
    'Darwin': { include vagrant_installer::package::darwin }
    default:  { fail("Unknown operating system to package for.") }
  }
}
