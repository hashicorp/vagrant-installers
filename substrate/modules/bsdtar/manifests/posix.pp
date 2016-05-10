class bsdtar::posix {
  require build_essential

  $autotools_environment = $bsdtar::autotools_environment
  $file_cache_dir        = $bsdtar::file_cache_dir
  $install_dir           = $bsdtar::install_dir

  $source_dir_path = "${file_cache_dir}/libarchive-3.1.2"
  $source_package_path = "${file_cache_dir}/libarchive.tar.gz"
  $source_url = "https://github.com/libarchive/libarchive/archive/v3.1.2.tar.gz"

  $configure_flags = "--prefix=${install_dir} --disable-dependency-tracking --with-zlib --without-bz2lib --without-iconv --without-libiconv-prefix --without-nettle --without-openssl --without-xml2 --without-expat"

  # We don't currently support LZMA on Linux. TODO
  $real_configure_flags = $operatingsystem ? {
    "Darwin"  => "$configure_flags --without-libregex",
    "FreeBSD" => "$configure_flags --without-lzmadec --without-lzma",
    default   => "${configure_flags} --without-libregex --without-lzmadec --without-lzma",
  }


  # Determine if we have an extra environmental variables we need to set
  # based on the operating system.
  if $operatingsystem == 'Darwin' {
    $extra_autotools_environment = {
      "CFLAGS"  => "-arch i386",
      "LDFLAGS" => "-arch i386 -Wl,-rpath,${install_dir}/lib",
    }
  } elsif $operatingsystem == 'FreeBSD' {
    $extra_autotools_environment = {
      "CFLAGS"  => "-fPIC",
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
    # Make sure we have a later version of automake/autoconf
    homebrew::package { "automake":
      creates => "/usr/local/bin/automake",
      link    => true,
      before  => Exec["automake-libarchive"],
    }

    homebrew::package { "autoconf":
      creates => "/usr/local/bin/autoconf",
      link    => true,
      before  => Exec["automake-libarchive"],
    }

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

  #------------------------------------------------------------------
  # Compile
  #------------------------------------------------------------------
  # Create configuration script
  exec { "automake-libarchive":
    command => "/bin/sh build/autogen.sh",
    creates => "${source_dir_path}/configure",
    cwd     => $source_dir_path,
    require => Exec["untar-libarchive"],
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
    exec { "remove-bsdtar-rpath":
      command     => "install_name_tool -delete_rpath ${install_dir}/lib ${install_dir}/bin/bsdtar",
      refreshonly => true,
      require     => Autotools["libarchive"],
      subscribe   => Autotools["libarchive"],
    }
  }
}
