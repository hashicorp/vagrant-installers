# == Class: homebrew
#
# This installs homebrew, a package manager for Mac OS X.
#
class homebrew {
  include homebrew::params

  $user = $homebrew::params::user

  $directories = [ '/usr/local',
                   '/usr/local/bin',
                   '/usr/local/etc',
                   '/usr/local/include',
                   '/usr/local/lib',
                   '/usr/local/lib/pkgconfig',
                   '/usr/local/Library',
                   '/usr/local/sbin',
                   '/usr/local/share',
                   '/usr/local/var',
                   '/usr/local/var/log',
                   '/usr/local/share/locale',
                   '/usr/local/share/man',
                   '/usr/local/share/man/man1',
                   '/usr/local/share/man/man2',
                   '/usr/local/share/man/man3',
                   '/usr/local/share/man/man4',
                   '/usr/local/share/man/man5',
                   '/usr/local/share/man/man6',
                   '/usr/local/share/man/man7',
                   '/usr/local/share/man/man8',
                   '/usr/local/share/info',
                   '/usr/local/share/doc',
                   '/usr/local/share/aclocal' ]

  file { $directories:
    ensure   => directory,
    owner    => $user,
    group    => 'admin',
    mode     => 0775,
  }

  exec { 'install-homebrew':
    command   => "/usr/bin/su ${user} -c '/bin/bash -o pipefail -c \"/usr/bin/curl -skSfL https://github.com/mxcl/homebrew/tarball/master | /usr/bin/tar xz -m --strip 1\"'",
    creates   => '/usr/local/bin/brew',
    cwd       => '/usr/local',
    logoutput => on_failure,
    timeout   => 0,
    require   => File[$directories],
  }

  file { '/usr/local/bin/brew':
    owner     => $user,
    group     => 'admin',
    mode      => 0775,
    require   => Exec['install-homebrew'],
  }
}
