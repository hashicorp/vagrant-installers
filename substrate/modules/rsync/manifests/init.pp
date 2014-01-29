# == Class: rsync
#
# This installs rsync.
#
class rsync {
  case $operatingsystem {
    'Archlinux': {
      package { "rsync":
        ensure => installed,
      }
    }
  }
}
