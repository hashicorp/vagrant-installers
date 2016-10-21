class vagrant_substrate::staging::posix {
  include vagrant_substrate

  $cache_dir         = $vagrant_substrate::cache_dir
  $embedded_dir      = $vagrant_substrate::embedded_dir
  $staging_dir       = $vagrant_substrate::staging_dir
  $installer_version = $vagrant_substrate::installer_version

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

    $bsdtar_autotools_environment = {
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

    $openssl_autotools_environment = {
      "LDFLAGS" => "-Wl,-rpath,@loader_path/../lib -Wl,-rpath,@executable_path/../lib",
    }

    $libssh2_autotools_environment = {
      "LDFLAGS" => "-Wl,-install_name,@rpath/libssh2.dylib -Wl,-rpath,@loader_path/../lib -Wl,-rpath,@executable_path/../lib",
    }

    $xz_autotools_environment = {
      "LDFLAGS" => "-Wl,-install_name,@rpath/liblzma.dylib",
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
  class { "atlas_upload_cli":
    install_path => "${embedded_dir}/bin/atlas-upload",
  }

  class { "libffi":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $libffi_autotools_environment),
    file_cache_dir => $cache_dir,
    prefix         => $embedded_dir,
    make_notify   => Exec["reset-ruby"],
  }

  class { "libiconv":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $libiconv_autotools_environment),
      file_cache_dir => $cache_dir,
      prefix         => $embedded_dir,
  }

  class { "libxml2":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $libxml2_autotools_environment),
      file_cache_dir => $cache_dir,
      prefix         => $embedded_dir,
      require        => [
        Class["libiconv"],
        Class["xz"],
      ],
  }

  class { "libxslt":
    autotools_environment => $default_autotools_environment,
    file_cache_dir        => $cache_dir,
    prefix                => $embedded_dir,
    require               => Class["libxml2"],
  }

  class { "libyaml":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $libyaml_autotools_environment),
    file_cache_dir => $cache_dir,
    prefix         => $embedded_dir,
    make_notify    => Exec["reset-ruby"],
  }

  class { "zlib":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $zlib_autotools_environment),
    file_cache_dir => $cache_dir,
    prefix         => $embedded_dir,
    make_notify    => Exec["reset-ruby"],
  }

  class { "xz":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $xz_autotools_environment),
    file_cache_dir => $cache_dir,
    prefix         => $embedded_dir,
    make_notify    => Exec["reset-ruby"],
  }

  class { "readline":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $readline_autotools_environment),
    file_cache_dir => $cache_dir,
    prefix         => $embedded_dir,
    make_notify    => Exec["reset-ruby"],
  }

  class { "openssl":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $openssl_autotools_environment),
    file_cache_dir        => $cache_dir,
    prefix                => $embedded_dir,
    make_notify           => Exec["reset-ruby"],
  }

  class { "libssh2":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $libssh2_autotools_environment),
    file_cache_dir        => $cache_dir,
    prefix                => $embedded_dir,
    require               => Class["openssl"],
  }

  class { "bsdtar":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $bsdtar_autotools_environment),
    file_cache_dir => $cache_dir,
    install_dir    => $embedded_dir,
    require        => [
      Class["xz"],
      Class["zlib"],
    ]
  }

  class { "curl":
    autotools_environment => autotools_merge_environments(
      $default_curl_autotools_environment, $curl_autotools_environment),
    file_cache_dir        => $cache_dir,
    install_dir           => $embedded_dir,
    require               => [
      Class["openssl"],
      Class["zlib"],
    ],
  }

  class { "ruby::source":
    autotools_environment => autotools_merge_environments(
      $default_autotools_environment, $ruby_autotools_environment),
    file_cache_dir        => $cache_dir,
    prefix                => $embedded_dir,
    require               => [
      Class["libffi"],
      Class["libyaml"],
      Class["zlib"],
      Class["openssl"],
      Class["readline"],
    ],
  }

  class { "rubyencoder::loaders":
    path => $embedded_dir,
  }
}
