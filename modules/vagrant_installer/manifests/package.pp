# == Class: vagrant_installer::package
#
# This makes the installer package for Vagrant.
#
class vagrant_installer::package {
  case $operatingsystem {
    'Archlinux': { include vagrant_installer::package::arch }
    'CentOS': { include vagrant_installer::package::centos }
    'Darwin': { include vagrant_installer::package::darwin }
    'Ubuntu': { include vagrant_installer::package::ubuntu }
    'windows': { include vagrant_installer::package::windows }
    'FreeBSD': { include vagrant_installer::package::freebsd }
    default:  { fail("Unknown operating system to package for.") }
  }
}
