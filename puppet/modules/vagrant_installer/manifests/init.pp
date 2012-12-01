# == Class: vagrant_installer
#
# This creates a Vagrant installer for the platform that this is
# run on.
#
class vagrant_installer {
  include vagrant_installer::params

  $embedded_dir = $vagrant_installer::params::embedded_dir

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

  #------------------------------------------------------------------
  # Classes
  #------------------------------------------------------------------
  class { "vagrant_installer::prepare":
    stage => "prepare",
  }

  class { "libffi":
    autotools_environment => $default_autotools_environment,
    prefix                => $embedded_dir,
  }

  class { "libyaml":
    autotools_environment => $default_autotools_environment,
    prefix                => $embedded_dir,
  }

  class { "zlib":
    autotools_environment => $default_autotools_environment,
    prefix                => $embedded_dir,
  }

  class { "readline":
    autotools_environment => $default_autotools_environment,
    prefix                => $embedded_dir,
  }

  class { "openssl":
    autotools_environment => $default_autotools_environment,
    prefix                => $embedded_dir,
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
    revision              => "ee713a0e70d8881ba5b30a0f5612bd7a4884277a",
    require               => Class["ruby"],
  }
}
