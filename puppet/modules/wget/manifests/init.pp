# == Class: wget
#
# This installs wget.
#
class wget {
  package { "wget":
    ensure => installed,
  }
}
