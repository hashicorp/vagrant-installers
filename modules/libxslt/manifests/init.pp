# == Class: libxslt
#
# This installs libxslt from source.
#
class libxslt(
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $make_notify = undef,
  $prefix = params_lookup('prefix'),
) {
  require build_essential

  $source_filename  = "libxslt-1.1.28.tar.gz"
  $source_url = "ftp://xmlsoft.org/libxml2/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  # Determine if we have an extra environmental variables we need to set
  # based on the operating system.
  if $operatingsystem == 'Darwin' {
    $extra_autotools_environment = {
      "CFLAGS"  => "-arch i386 -arch x86_64",
      "LDFLAGS" => "-arch i386 -arch x86_64",
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
  wget::fetch { "libxslt":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-libxslt":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["libxslt"],
  }

  autotools { "libxslt":
    configure_flags  => "--prefix=${prefix} --disable-dependency-tracking --with-libxml-prefix=${prefix}",
    cwd              => $source_dir_path,
    environment      => $real_autotools_environment,
    install_sentinel => "${prefix}/lib/libxslt.a",
    make_notify      => $make_notify,
    make_sentinel    => "${source_dir_path}/libxslt/.libs/libxslt.dylib",
    require          => Exec["untar-libxslt"],
  }

  #------------------------------------------------------------------
  # Mac OS X lib name setup
  #------------------------------------------------------------------
  if $operatingsystem == 'Darwin' {
    # XSLT
    $xslt_path     = "${prefix}/lib/libxslt.dylib"
    $old_xslt_path = "${prefix}/lib/libxslt.1.dylib"
    $new_xslt_path = "@rpath/libxslt.1.dylib"

    exec { "libxslt-rpath":
      command     => "install_name_tool -id ${new_xslt_path} ${xslt_path}",
      refreshonly => true,
      require     => Autotools["libxslt"],
      subscribe   => Exec["untar-libxslt"],
    }

    # EXSLT
    $exslt_path     = "${prefix}/lib/libexslt.dylib"
    $old_exslt_path = "${prefix}/lib/libexslt.0.dylib"
    $new_exslt_path = "@rpath/libexslt.0.dylib"

    exec { "libexslt-rpath":
      command     => "install_name_tool -id ${new_exslt_path} ${exslt_path}",
      refreshonly => true,
      require     => Autotools["libxslt"],
      subscribe   => Exec["untar-libxslt"],
    }

    exec { "libexslt-xslt-rpath":
      command     => "install_name_tool -change ${old_xslt_path} ${new_xslt_path} ${exslt_path}",
      refreshonly => true,
      require     => Autotools["libxslt"],
      subscribe   => Exec["untar-libxslt"],
    }
  }
}
