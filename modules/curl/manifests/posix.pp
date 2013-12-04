class curl::posix {
  require build_essential

  $autotools_environment = $curl::autotools_environment
  $file_cache_dir        = $curl::file_cache_dir
  $install_dir           = $curl::install_dir

  $source_filename  = "curl-7.33.0.tar.gz"
  $source_url = "http://curl.haxx.se/download/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  # Determine if we have an extra environmental variables we need to set
  # based on the operating system.
  if $operatingsystem == 'Darwin' {
    $extra_autotools_environment = {
      "CFLAGS"  => "-arch i386",
      "LDFLAGS" => "-arch i386 -Wl,-rpath,${install_dir}/lib",
    }
  } else {
    $extra_autotools_environment = {
      "LD_RUN_PATH" => "${install_dir}/lib",
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
    configure_flags    => "--prefix=${install_dir} --disable-dependency-tracking --disable-ldap",
    configure_sentinel => "${source_dir_path}/src/Makefile",
    cwd                => $source_dir_path,
    environment        => $real_autotools_environment,
    install_sentinel   => "${install_dir}/bin/curl",
    make_sentinel      => "${source_dir_path}/src/.libs/curl",
    require            => Exec["untar-curl"],
  }

  if $operatingsystem == 'Darwin' {
    # On Mac OS X, we add a temporary rpath value so that the ./configure
    # passes properly. In this step, we remove that temporary rpath value
    # because we don't actually need it in the resulting binary.
    exec { "remove-temp-curl-rpath":
      command     => "install_name_tool -delete_rpath ${install_dir}/lib ${install_dir}/bin/curl",
      refreshonly => true,
      require     => Autotools["curl"],
      subscribe   => Autotools["curl"],
    }

    $original_dylib = "${install_dir}/lib/libcurl.4.dylib"
    $rpath_dylib    = "@rpath/libcurl.4.dylib"

    # Now to flip a bunch of bits so that things point to the proper
    # locations.
    exec { "change-id-libcurl":
      command     => "install_name_tool -id ${rpath_dylib} ${original_dylib}",
      refreshonly => true,
      require     => Autotools["curl"],
      subscribe   => Autotools["curl"],
    }

    exec { "change-curl-libcurl-dep":
      command     => "install_name_tool -change ${original_dylib} ${rpath_dylib} ${install_dir}/bin/curl",
      refreshonly => true,
      require     => Autotools["curl"],
      subscribe   => Autotools["curl"],
    }
  }

  if $kernel == 'Linux' {
    # We need to clean up the rpaths...
    exec { "curl-rpath":
      command => "chrpath -r '\${ORIGIN}/../lib' ${install_dir}/bin/curl",
      refreshonly => true,
      require     => Autotools["curl"],
      subscribe   => Autotools["curl"],
    }
  }
}
