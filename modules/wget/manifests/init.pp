# == Class: wget
#
# This installs wget.
#
class wget {
  if $operatingsystem == 'Darwin' {
    # Install via homebrew
    homebrew::package { "wget":
      creates     => "/usr/local/bin/wget",
    }
  } elsif $operatingsystem == 'FreeBSD' {
    package { "wget":
      ensure   => installed,
      provider => pkgng,
    }
  } else { 
    package { "wget":
      ensure   => installed,
    }
  }
}
