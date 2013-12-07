# == Class: vagrant_installer::staging::posix
#
# This sets up the staging directory for POSIX compliant systems.
#
class vagrant_installer::staging::posix {
  include vagrant_installer::params

  $embedded_dir     = $vagrant_installer::params::embedded_dir
  $installer_version = $vagrant_installer::params::installer_version
  $staging_dir      = $vagrant_installer::params::staging_dir
  $vagrant_revision = $vagrant_installer::params::vagrant_revision

  #------------------------------------------------------------------
  # Calculate variables based on operating system
  #------------------------------------------------------------------
  $extra_autotools_ldflags = $operatingsystem ? {
    'Darwin' => "",
    default  => '',
  }

  $default_autotools_environment = {
    "CFLAGS"                   =>
      "-I${embedded_dir}/include",
    "LDFLAGS"                  =>
      "-L${embedded_dir}/lib ${extra_autotools_ldflags}",
    "MACOSX_DEPLOYMENT_TARGET" => "10.5",
  }

  $default_curl_autotools_environment = {
    "CPPFLAGS"                 => "-I${embedded_dir}/include",
    "LDFLAGS"                  => "-L${embedded_dir}/lib ${extra_autotools_ldflags}",
    "MACOSX_DEPLOYMENT_TARGET" => "10.5",
  }

  if $operatingsystem == 'Darwin' {
    $curl_autotools_environment = {
      "LDFLAGS" => "-Wl,-rpath,@loader_path/../lib -Wl,-rpath,@executable_path/../lib",
    }

    $libffi_autotools_environment = {
      "LDFLAGS" => "-Wl,-install_name,@rpath/libffi.dylib",
    }

    $libiconv_autotools_environment = {
      "LDFLAGS" => "-Wl,-install_name,@rpath/libiconv.dylib",
    }

    $libxml2_autotools_environment = {
      "LDFLAGS" => "-Wl,-install_name,@rpath/libxml2.dylib",
    }

    $libyaml_autotools_environment = {
      "LDFLAGS" => "-Wl,-install_name,@rpath/libyaml.dylib",
    }

    $readline_autotools_environment = {
      "LDFLAGS" => "-Wl,-install_name,@rpath/libreadline.dylib",
    }

    $ruby_autotools_environment = {
      "LDFLAGS" => "-Wl,-rpath,@loader_path/../lib -Wl,-rpath,@executable_path/../lib",
    }

    $zlib_autotools_environment = {
      "LDFLAGS" => "-Wl,-install_name,@rpath/libz.dylib",
    }
  } elsif $kernel == 'Linux' {
    $bsdtar_autotools_environment = {
      "LD_RUN_PATH" => '$ORIGIN/../lib',
    }

    $ruby_autotools_environment = {
      "LD_RUN_PATH" => '\$ORIGIN/../lib',
    }
  }

  #------------------------------------------------------------------
  # Classes
  #------------------------------------------------------------------
  class { "libffi":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $libffi_autotools_environment),
    prefix      => $embedded_dir,
    make_notify => Exec["reset-ruby"],
    tag         => "platform",
  }

  if $operatingsystem == "Ubuntu" or $operatingsystem == "Darwin" {
    class { "libiconv":
      autotools_environment => autotools_merge_environments(
        $default_autotools_environment, $libiconv_autotools_environment),
        prefix => $embedded_dir,
      tag      => "platform",
    }

    class { "libxml2":
      autotools_environment => autotools_merge_environments(
        $default_autotools_environment, $libxml2_autotools_environment),
      prefix  => $embedded_dir,
      require => Class["libiconv"],
      tag     => "platform",
    }

    class { "libxslt":
      autotools_environment => $default_autotools_environment,
      prefix                => $embedded_dir,
      require               => Class["libxml2"],
      tag                   => "platform",
    }
  }

  class { "libyaml":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $libyaml_autotools_environment),
    prefix      => $embedded_dir,
    make_notify => Exec["reset-ruby"],
    tag         => "platform",
  }

  class { "zlib":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $zlib_autotools_environment),
    prefix      => $embedded_dir,
    make_notify => Exec["reset-ruby"],
    tag         => "platform",
  }

  class { "readline":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $readline_autotools_environment),
    prefix      => $embedded_dir,
    make_notify => Exec["reset-ruby"],
    tag         => "platform",
  }

  class { "openssl":
    autotools_environment => $default_autotools_environment,
    prefix                => $embedded_dir,
    make_notify           => Exec["reset-ruby"],
    tag                   => "platform",
  }

  class { "bsdtar":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $bsdtar_autotools_environment),
    install_dir => $embedded_dir,
    require     => Class["zlib"],
    tag         => "platform",
  }

  class { "curl":
    autotools_environment => autotools_merge_environments(
      $default_curl_autotools_environment, $curl_autotools_environment),
    install_dir           => $embedded_dir,
    require               => [
      Class["openssl"],
      Class["zlib"],
    ],
    tag => "platform",
  }

  class { "ruby::source":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $ruby_autotools_environment),
    prefix                => $embedded_dir,
    make_notify           => Exec["reset-vagrant"],
    require               => [
      Class["libffi"],
      Class["libyaml"],
      Class["zlib"],
      Class["openssl"],
      Class["readline"],
    ],
    tag => "platform",
  }

  class { "rubyencoder::loaders":
    path => $embedded_dir,
    tag  => "platform",
  }

  class { "vagrant":
    autotools_environment => $default_autotools_environment,
    embedded_dir          => $embedded_dir,
    revision              => $vagrant_revision,
    tag                   => "platform",
    require               => Class["ruby::source"],
  }

  #------------------------------------------------------------------
  # Optimize some disk space
  #------------------------------------------------------------------

  exec { "clear-openssl-man":
    command => "rm -rf ${embedded_dir}/ssl/man",
    require => Class["openssl"],
  }

  # We have to remove all the '.la' files because they cause issues
  # with libtool later because they have hardcoded temp paths in them.
  exec { "remove-la-files":
    command => "rm -rf ${embedded_dir}/lib/*.la",
  }

  Class <| tag == "platform" |> -> Exec["remove-la-files"]

  #------------------------------------------------------------------
  # Other files
  #------------------------------------------------------------------
  $gemrc_path = "${embedded_dir}/etc/gemrc"

  file { $gemrc_path:
    content => template("vagrant_installer/gemrc.erb"),
    mode    => "0644",
  }

  file { "${embedded_dir}/cacert.pem":
    source => "puppet:///modules/vagrant_installer/cacert.pem",
    mode   => "0644",
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
}
