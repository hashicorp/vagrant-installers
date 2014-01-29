# == Class: fog
#
# This installs the fog gem.
#
class fog {
  require build_essential
  require ruby

  $pre_packages = $operatingsystem ? {
    'Archlinux' => ["libxml2", "libxslt"],
    'CentOS'    => ["libxml2", "libxml2-devel", "libxslt", "libxslt-devel"],
    'Darwin'    => [],
    'Ubuntu'    => ["libxml2-dev", "libxslt1-dev"],
    default     => fail("Unknown operating system."),
  }

  package { $pre_packages:
    ensure => installed,
    before => Package["fog"],
  }

  package { "fog":
    provider => gem,
  }
}
