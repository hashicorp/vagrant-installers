# == Define: autotools
#
# This compiles and installs software that follows autotools-like
# patterns: configure, make, make install.
#
# === Parameters:
#
# [*configure_file*]
#   The file to be called for the configure step. Defaults to "./configure"
#
# [*configure_flags*]
#   A string of flags to pass to configure. This could be something like
#   "--prefix=/home/foo" and so on. This is passed directly to the
#   configure_file.
#
# [*configure_sentinel*]
#   This is the path to a sentinel file denoting that the configuration
#   step has completed. By default this resource will search for a Makefile
#   in your working directory. If this file exists, the configure step
#   is not run.
#
# [*cwd*]
#   This is the working directory where all the commands (such as make)
#   are executed from.
#
# [*environment*]
#   This is a hash of environmental variables to set while calling each
#   step.
#
# [*install*]
#   If this is true, `make install` is called. If this is false, the
#   install step is skipped.
#
# [*install_sentinel*]
#   This is the path to a sentinel file denoting that the install step
#   has already completed. By default this is nothing, and `make install`
#   will be called every time.
#
# [*make_command*]
#   This is the command to execute to compile. By default this is `make`
#
# [*make_notify*]
#   This should point to a resource that is notified when `make` is called.
#   This can be used to know when only the compilation step is redone.
#
# [*make_sentinel*]
#   This is the path to a sentinel file denoting that the make step
#   has already completed. By default this is nothing, and `make` runs
#   every time.
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
  $make_notify=undef,
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
    provider    => shell,
    environment => $exec_environment,
  }

  exec { "make-${name}":
    command     => $real_make_command,
    creates     => $make_sentinel,
    cwd         => $cwd,
    environment => $exec_environment,
    require     => Exec["configure-${name}"],
    notify      => $make_notify,
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
