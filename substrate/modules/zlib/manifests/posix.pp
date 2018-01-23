class zlib::posix {
  require build_essential

  $file_cache_dir = $zlib::file_cache_dir
  $prefix = $zlib::prefix
  $autotools_environment = $zlib::autotools_environment
  $make_notify = $zlib::make_notify

  $lib_version = hiera("zlib::version")
  $source_filename  = "zlib-${lib_version}.tar.gz"
  $source_url = "http://zlib.net/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  $lib_short_version = inline_template("<%= @lib_version.split('.').first %>")

  # Determine if we have an extra environmental variables we need to set
  # based on the operating system.
  if $operatingsystem == 'Darwin' {
    $extra_autotools_environment = {
      "CFLAGS"  => "-arch x86_64",
      "LDFLAGS" => "-arch x86_64",
    }
  } else {
    $extra_autotools_environment = {}
  }

  # Merge our environments.
  $real_autotools_environment = autotools_merge_environments(
    $autotools_environment, $extra_autotools_environment)

  #------------------------------------------------------------------
  # Compile
  #------------------------------------------------------------------
  wget::fetch { "libz":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-libz":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["libz"],
  }

  autotools { "libz":
    configure_flags    => "--prefix=${prefix}",
    configure_sentinel => "${source_dir_path}/zlib.pc",
    cwd                => $source_dir_path,
    environment        => $real_autotools_environment,
    install_sentinel   => "${prefix}/lib/libz.a",
    make_notify        => $make_notify,
    make_sentinel      => "${source_dir_path}/libz.a",
    require            => Exec["untar-libz"],
  }

  if $kernel == 'Darwin' {
    $libz_paths = [
      "${prefix}/lib/libz.dylib",
      "${prefix}/lib/libz.${lib_short_version}.dylib",
      "${prefix}/lib/libz.${lib_version}.dylib",
    ]
    $lib_path = "@rpath/libz.${lib_short_version}.dylib"
    $embedded_dir = "${prefix}/lib"

    vagrant_substrate::staging::darwin_rpath { $libz_paths:
      new_lib_path => $lib_path,
      remove_rpath => $embedded_dir,
      require => Autotools["libz"],
      subscribe => Autotools["libz"],
    }
  }

  if $kernel == 'Linux' {
    $libz_paths = [
      "${prefix}/lib/libz.so",
    ]

    vagrant_substrate::staging::linux_chrpath{ $libz_paths:
      require => Autotools["libz"],
      subscribe => Autotools["libz"],
    }
  }
}
