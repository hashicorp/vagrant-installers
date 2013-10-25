class bsdtar::posix {
  require build_essential

  $autotools_environment = $bsdtar::autotools_environment
  $file_cache_dir        = $bsdtar::file_cache_dir
  $install_dir           = $bsdtar::install_dir

  $source_dir_path = "${file_cache_dir}/libarchive-3.1.2"
  $source_package_path = "${file_cache_dir}/libarchive.tar.gz"
  $source_url = "https://github.com/libarchive/libarchive/archive/v3.1.2.tar.gz"

  # Determine if we have an extra environmental variables we need to set
  # based on the operating system.
  if $operatingsystem == 'Darwin' {
    $extra_autotools_environment = {
      "CFLAGS"  => "-arch i386",
      "LDFLAGS" => "-arch i386",
    }
  } else {
    $extra_autotools_environment = {}
  }

  # Merge our environments.
  $real_autotools_environment = autotools_merge_environments(
    $autotools_environment, $extra_autotools_environment)

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
    source      => $source_url,
    destination => $source_package_path,
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
    configure_flags  => "--prefix=${install_dir} --disable-dependency-tracking --with-zlib --without-bz2lib --without-lzmadec --without-iconv --without-libiconv-prefix --without-lzma --without-nettle --without-openssl --without-xml2 --without-expat",
    cwd              => $source_dir_path,
    #environment      => $real_autotools_environment,
    install_sentinel => "${install_dir}/bin/bsdtar",
    make_sentinel    => "${source_dir_path}/bsdtar",
    require          => Exec["automake-libarchive"],
  }

  #------------------------------------------------------------------
  # Modify
  #------------------------------------------------------------------
  # On OS X we want to setup the rpath properly for the executable
  if $kernel == 'Darwin' {
    exec { "bsdtar-rpath":
      command     => "install_name_tool -add_rpath '@executable_path/../lib' ${install_dir}/bin/bsdtar",
      refreshonly => true,
      subscribe   => Autotools["libarchive"],
      require     => Autotools["libarchive"],
    }
  }
}
