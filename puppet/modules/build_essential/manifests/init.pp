# == Class: build_essential
#
# This will install the base development tools for multiple platforms.
#
class build_essential {
  if $operatingsystem == 'Ubuntu' {
    package {
      ["build-essential", "autoconf", "automake", "libtool"]:
        ensure => installed,
    }
  }
}
