# == Class: patch::setups
#
# This installs patch. This doesn't need to be called directly. The
# patch definition will call this.
class patch::setup {
  if $operatingsystem == 'Ubuntu' {
    package { "patch":
      ensure => installed,
    }
  }
}
