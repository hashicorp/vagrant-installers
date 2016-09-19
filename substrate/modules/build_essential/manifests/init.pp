# == Class: build_essential
#
# This will install the base development tools for multiple platforms.
#
class build_essential {
  case $operatingsystem {
    'Archlinux': {
      exec { "pacman-base-devel":
        command => "pacman --noconfirm --noprogressbar -Sy base-devel",
        unless  => "pacman -Qg base-devel",
      }

      exec { "pacman-chrpath":
        command => "pacman --noconfirm --noprogressbar -Sy chrpath",
        unless  => "pacman -Qq chrpath",
      }
    }

    'CentOS': {
      package { ["chrpath", "gcc", "make", "perl"]:
        ensure => installed,
      }

      $script_build_autotools = "/usr/local/bin/centos_build_autotools"

      util::script { $script_build_autotools:
        content => template("build_essential/centos_build_autotools.sh.erb"),
      }

      exec { $script_build_autotools:
        unless  => "test -f /usr/local/bin/m4",
        require => [
          Package["gcc"],
          Package["make"],
          Util::Script[$script_build_autotools],
        ],
      }
    }

    'Ubuntu': {
      package {
        ["build-essential", "autoconf", "automake", "chrpath", "libtool", "pkg-config"]:
          ensure => installed,
      }
    }
  }
}
