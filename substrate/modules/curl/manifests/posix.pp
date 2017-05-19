class curl::posix {
  require build_essential
  require libssh2

  $autotools_environment = $curl::autotools_environment
  $file_cache_dir        = $curl::file_cache_dir
  $install_dir           = $curl::install_dir

  $source_filename  = "curl-7.49.0.tar.gz"
  $source_url = "http://curl.haxx.se/download/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  $lib_version = "4"

  # Determine if we have an extra environmental variables we need to set
  # based on the operating system.
  if $operatingsystem == 'Darwin' {
    $extra_autotools_environment = {
      "CFLAGS"  => "-arch x86_64",
      "LDFLAGS" => "-arch x86_64 -Wl,-rpath,${install_dir}/lib",
    }
  } else {
    $extra_autotools_environment = {
    }
  }

  # Merge our environments.
  $real_autotools_environment = autotools_merge_environments(
    $autotools_environment, $extra_autotools_environment)

  #------------------------------------------------------------------
  # Compile
  #------------------------------------------------------------------
  wget::fetch { "curl":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-curl":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["curl"],
  }

  autotools { "curl":
    configure_flags    => "--prefix=${install_dir} --disable-dependency-tracking --disable-ldap --with-libssh2",
    configure_sentinel => "${source_dir_path}/src/Makefile",
    cwd                => $source_dir_path,
    environment        => $real_autotools_environment,
    install_sentinel   => "${install_dir}/bin/curl",
    make_sentinel      => "${source_dir_path}/src/.libs/curl",
    require            => Exec["untar-curl"],
  }

  if $operatingsystem == 'Darwin' {

    $libcurl_paths = [
      "${install_dir}/lib/libcurl.dylib",
      "${install_dir}/lib/libcurl.${lib_version}.dylib"
    ]
    $lib_path = "@rpath/libcurl.${lib_version}.dylib"
    $embedded_libdir = "${install_dir}/lib"

    vagrant_substrate::staging::darwin_rpath { $libcurl_paths:
      new_lib_path => $lib_path,
      remove_rpath => $embedded_libdir,
      require => Autotools["curl"],
      subscribe => Autotools["curl"],
    }

    vagrant_substrate::staging::darwin_rpath { "${install_dir}/bin/curl":
      change_install_names => {
        libcurl => {
          original => "${install_dir}/lib/libcurl.${lib_version}.dylib",
          replacement => $lib_path,
        }
      },
      new_lib_path => $lib_path,
      remove_rpath => $embedded_libdir,
      require => Autotools["curl"],
      subscribe => Autotools["curl"],
    }
  }

  if $kernel == 'Linux' {
    # We need to clean up the rpaths...
    $libcurl_paths = [
      "${install_dir}/bin/curl",
      "${install_dir}/lib/libcurl.so",
    ]

    vagrant_substrate::staging::linux_chrpath{ $libcurl_paths:
      require => Autotools["curl"],
      subscribe => Autotools["curl"],
    }
  }
}
