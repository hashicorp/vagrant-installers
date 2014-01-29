# == Class: vagrant_installer::staging::posix
#
# This sets up the staging directory for POSIX compliant systems.
#
class vagrant_installer::staging::posix {
  include vagrant_installer::staging::posix_setup

  class { "vagrant_installer::staging::posix_postinstall":
    require => Class["vagrant_installer::staging::posix_setup"],
  }
}
