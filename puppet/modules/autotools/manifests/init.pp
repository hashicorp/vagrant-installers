# == Define: autotools
#
# This compiles and installs software with autotools.
#
define autotools(
  $configure_file=undef,
  $configure_flags="",
  $configure_sentinel=undef,
  $cwd,
  $environment=undef,
  $install=true,
  $install_sentinel=undef,
  $make_command=undef,
  $make_sentinel=undef,
) {
  $real_configure_file = $configure_file ? {
    undef   => "./configure",
    default => $configure_file,
  }

  $real_configure_sentinel = $configure_sentinel ? {
    undef   => "${cwd}/Makefile",
    default => $configure_sentinel,
  }

  $real_make_command = $make_command ? {
    undef   => "make",
    default => $make_command,
  }

  $exec_environment = $environment ? {
    undef   => undef,
    default => autotools_flatten_environment($environment),
  }

  exec { "configure-${name}":
    command     => "sh ${real_configure_file} ${configure_flags}",
    creates     => $real_configure_sentinel,
    cwd         => $cwd,
    environment => $exec_environment,
  }

  exec { "make-${name}":
    command     => $real_make_command,
    creates     => $make_sentinel,
    cwd         => $cwd,
    environment => $exec_environment,
    require     => Exec["configure-${name}"],
  }

  if $install {
    exec { "make-install-${name}":
      command     => "make install",
      creates     => $install_sentinel,
      cwd         => $cwd,
      environment => $exec_environment,
      require     => Exec["make-${name}"],
    }
  }
}
