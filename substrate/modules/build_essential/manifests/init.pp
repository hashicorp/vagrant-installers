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

      exec { "perl-Data-Dumper":
        command => "/usr/bin/yum -d 0 -e 0 -y install perl-Data-Dumper",
        onlyif => "/usr/bin/yum -d 0 -e 0 -y list perl-Data-Dumper",
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

    'Darwin': {
      $script_build_autotools = "/usr/local/bin/darwin_build_autotools"

      util::script { $script_build_autotools:
        content => template("build_essential/darwin_build_autotools.sh.erb"),
      }

      exec { $script_build_autotools:
        unless  => "test -f /usr/local/bin/automake",
        require => [
          Util::Script[$script_build_autotools],
        ],
      }
    }

    'Ubuntu': {
      package {
        ["build-essential", "autoconf", "automake", "chrpath", "libtool"]:
          ensure => installed,
      }

      $script_build_autotools = "/usr/local/bin/centos_build_autotools"

      util::script { $script_build_autotools:
        content => template("build_essential/centos_build_autotools.sh.erb"),
      }

      exec { $script_build_autotools:
        unless  => "test -f /usr/local/bin/m4",
        require => [
          Package["build-essential"],
          Util::Script[$script_build_autotools],
        ],
      }
    }
  }
}
