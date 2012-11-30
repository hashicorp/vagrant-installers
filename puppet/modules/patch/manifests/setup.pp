# == Class: patch::setups
#
# This installs patch. This doesn't need to be called directly. The
# patch definition will call this.
class patch::setup {
  package { "patch":
    ensure => installed,
  }
}
