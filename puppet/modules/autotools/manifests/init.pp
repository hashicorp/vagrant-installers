# == Define: autotools
#
# This compiles and installs software with autotools.
#
define autotools(
  $configure_flags="",
  $configure_sentinel=undef,
  $cwd,
  $environment=undef,
  $make_sentinel=undef,
) {
  $real_configure_sentinel = $configure_sentinel ? {
    undef   => "${cwd}/Makefile",
    default => $configure_sentinel,
  }

  $exec_environment = $environment ? {
    undef   => undef,
    default => autotools_flatten_environment($environment),
  }

  exec { "configure-${name}":
    command     => "sh ./configure ${configure_flags}",
    creates     => $real_configure_sentinel,
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
