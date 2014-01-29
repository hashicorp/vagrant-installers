# == Class: git
#
# This installs git.
#
class git {
  case $kernel {
    'Darwin': {
      homebrew::package { "git":
        creates => "/usr/bin/git",
      }
    }

    'Linux': {
      $package = $operatingsystem ? {
        'Archlinux' => "git",
        'CentOS'    => "git",
        default     => "git-core",
      }

      package { $package:
        ensure => installed,
      }
    }

    default: { fail("Unknown kernel.") }
  }
}
