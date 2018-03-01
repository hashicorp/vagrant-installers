class bsdtar::posix {
  require build_essential

  $autotools_environment = $bsdtar::autotools_environment
  $file_cache_dir        = $bsdtar::file_cache_dir
  $install_dir           = $bsdtar::install_dir

  $libarchive_version = hiera("libarchive::version")
  $source_dir_path = "${file_cache_dir}/libarchive-${libarchive_version}"
  $source_package_path = "${file_cache_dir}/libarchive.tar.gz"
  $source_url = "https://github.com/libarchive/libarchive/archive/v${libarchive_version}.tar.gz"

  $lib_version = "13"

  $configure_flags = "--prefix=${install_dir} --disable-dependency-tracking --with-zlib --without-bz2lib --without-iconv --without-libiconv-prefix --without-nettle --without-openssl --without-xml2 --without-expat"

  # We don't currently support LZMA on Linux. TODO
  $real_configure_flags = $operatingsystem ? {
    "Darwin" => $configure_flags,
    default  => "${configure_flags} --without-lzmadec --without-lzma",
  }


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

  # Set the LD_LIBRARY_PATH for the configure script
  $ld_path_environment = {
    "LD_LIBRARY_PATH" => "${install_dir}/lib",
  }

  # Merge our environments.
  $real_autotools_environment = autotools_merge_environments(
    $autotools_environment, $extra_autotools_environment, $ld_path_environment)

  if $kernel == 'Darwin' {
  #   # Make sure we have a later version of automake/autoconf
  #   homebrew::package { "automake":
  #     creates => "/usr/local/bin/automake",
  #     link    => true,
  #     before  => Exec["automake-libarchive"],
  #   }

  #   homebrew::package { "autoconf":
  #     creates => "/usr/local/bin/autoconf",
  #     link    => true,
  #     before  => Exec["automake-libarchive"],
  #   }

    homebrew::package { "libtool":
      creates => "/usr/local/bin/glibtoolize",
      before  => Exec["automake-libarchive"],
    }
  }

  #------------------------------------------------------------------
  # Download and Setup
  #------------------------------------------------------------------
  download { "libarchive":
    source         => $source_url,
    destination    => $source_package_path,
    file_cache_dir => $file_cache_dir,
  }

  exec { "untar-libarchive":
    command => "tar xvzf ${source_package_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Download["libarchive"],
  }

  if $kernel != 'Darwin' {
    # Even with the --without-xml2 flag set configure will try to expand
    # a libxml2 macro in the configure script which causes an error. This
    # scrubs the macro from the configure file allowing it to complete
    # successfully. This should be removed once the configure script properly
    # supports disabling of libxml2
    exec { "remove-libxml2-configure":
      command => "/bin/bash -c \"cat configure | tr '\\\\n' '\\\\r' | sed -e 's/PKG_PROG_PKG_CONFIG.*LIBXML2_PC.*xmlInitParser)\\\\r *)\\\\r//' | tr '\\\\r' '\\\\n' > configure.tmp && mv -f configure.tmp configure\"",
      cwd => $source_dir_path,
      require => Exec["automake-update-libarchive"],
    }

    #
    # Update automake files
    #
    exec { "automake-update-libarchive":
      command => "autoreconf -i || autoreconf -i",
      cwd => $source_dir_path,
      require => Exec["untar-libarchive"],
    }

    exec { "automake-libarchive":
      command => "/bin/sh build/autogen.sh",
      creates => "${source_dir_path}/configure",
      cwd     => $source_dir_path,
      require => Exec["remove-libxml2-configure"],
    }
  } else {
    exec { "automake-libarchive":
      command => "/bin/sh build/autogen.sh",
      creates => "${source_dir_path}/configure",
      cwd     => $source_dir_path,
      require => Exec["untar-libarchive"],
    }
  }

  # Build it
  autotools { "libarchive":
    configure_flags  => $real_configure_flags,
    cwd              => $source_dir_path,
    environment      => $real_autotools_environment,
    install_sentinel => "${install_dir}/bin/bsdtar",
    make_sentinel    => "${source_dir_path}/bsdtar",
    require          => Exec["automake-libarchive"],
  }

  if $kernel == 'Darwin' {
    $libarchive_paths = [
      "${install_dir}/lib/libarchive.dylib",
      "${install_dir}/lib/libarchive.${lib_version}.dylib",
      "${install_dir}/bin/bsdtar",
      "${install_dir}/bin/bsdcpio",
    ]
    $lib_path = "@rpath/libarchive.${lib_version}.dylib"
    $embedded_dir = "${install_dir}/lib"

    vagrant_substrate::staging::darwin_rpath { $libarchive_paths:
      new_lib_path => $lib_path,
      remove_rpath => $embedded_dir,
      require => Autotools["libarchive"],
      subscribe => Autotools["libarchive"],
    }
  }

  if $kernel == 'Linux' {
    $libarchive_paths = [
      "${install_dir}/lib/libarchive.so",
      "${install_dir}/bin/bsdtar",
      "${install_dir}/bin/bsdcpio",
    ]

    vagrant_substrate::staging::linux_chrpath{ $libarchive_paths:
      require => Autotools["libarchive"],
      subscribe => Autotools["libarchive"],
    }
  }
}
