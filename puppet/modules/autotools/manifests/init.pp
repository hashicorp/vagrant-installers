# == Define: autotools
#
# This compiles and installs software with autotools.
#
define autotools(
  $configure_flags="",
  $cwd,
  $environment=undef,
  $make_sentinel=undef,
) {
  $exec_environment = $environment ? {
    undef   => undef,
    default => autotools_flatten_environment($environment),
  }

  exec { "configure-${name}":
    command     => "sh ./configure ${configure_flags}",
    creates     => "${cwd}/Makefile",
    cwd         => $cwd,
    environment => $exec_environment,
  }

  exec { "make-${name}":
    command     => "make",
    creates     => $make_sentinel,
    cwd         => $cwd,
    environment => $exec_environment,
    require     => Exec["configure-${name}"],
  }

  exec { "make-install-${name}":
    command     => "make install",
    cwd         => $cwd,
    environment => $exec_environment,
    require     => Exec["make-${name}"],
  }
}
