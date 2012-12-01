# == Class: vagrant_installer
#
# This creates a Vagrant installer for the platform that this is
# run on.
#
class vagrant_installer {
  include vagrant_installer::params

  $embedded_dir     = $vagrant_installer::params::embedded_dir
  $staging_dir      = $vagrant_installer::params::staging_dir
  $vagrant_revision = $vagrant_installer::params::vagrant_revision

  #------------------------------------------------------------------
  # Calculate variables based on operating system
  #------------------------------------------------------------------
  $extra_autotools_ldflags = $operatingsystem ? {
    'Darwin' => "-R${embedded_dir}/lib",
    default  => '',
  }

  $default_autotools_environment = {
    "CFLAGS"                   =>
      "-I${embedded_dir}/include -L${embedded_dir}/lib",
    "LDFLAGS"                  =>
      "-I${embedded_dir}/include -L${embedded_dir}/lib ${extra_autotools_ldflags}",
    "MACOSX_DEPLOYMENT_TARGET" => "10.5",
  }

  #------------------------------------------------------------------
  # Run stages
  #------------------------------------------------------------------
  stage { "prepare": before => Stage["main"] }
  stage { "package": }

  Stage["main"] -> Stage["package"]

  #------------------------------------------------------------------
  # Classes
  #------------------------------------------------------------------
  class { "vagrant_installer::prepare":
    stage => "prepare",
  }

  class { "libffi":
    autotools_environment => $default_autotools_environment,
    prefix                => $embedded_dir,
    notify                => Exec["reset-ruby"],
  }

  class { "libyaml":
    autotools_environment => $default_autotools_environment,
    prefix                => $embedded_dir,
    notify                => Exec["reset-ruby"],
  }

  class { "zlib":
    autotools_environment => $default_autotools_environment,
    prefix                => $embedded_dir,
    notify                => Exec["reset-ruby"],
  }

  class { "readline":
    autotools_environment => $default_autotools_environment,
    prefix                => $embedded_dir,
    notify                => Exec["reset-ruby"],
  }

  class { "openssl":
    autotools_environment => $default_autotools_environment,
    prefix                => $embedded_dir,
    notify                => Exec["reset-ruby"],
  }

  class { "ruby":
    autotools_environment => $default_autotools_environment,
    prefix                => $embedded_dir,
    require               => [
      Class["libffi"],
      Class["libyaml"],
      Class["zlib"],
      Class["openssl"],
      Class["readline"],
    ],
  }

  class { "vagrant":
    autotools_environment => $default_autotools_environment,
    embedded_dir          => $embedded_dir,
    revision              => $vagrant_revision,
    require               => Class["ruby"],
  }

  #------------------------------------------------------------------
  # Bin wrappers
  #------------------------------------------------------------------
  # Vagrant
  file { "${staging_dir}/bin/vagrant":
    content => template("vagrant_installer/vagrant.erb"),
    mode    => "0755",
    require => Class["vagrant"],
  }

  #------------------------------------------------------------------
  # Package!
  #------------------------------------------------------------------
  class { "vagrant_installer::package":
    stage => "package",
  }
}
