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

  $source_filename  = "libxslt-1.1.29.tar.gz"
  $source_url = "ftp://xmlsoft.org/libxml2/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  $lib_version = "1"

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

  if $kernel == 'Darwin' {
    $libxslt_paths = [
      "${prefix}/lib/libxslt.dylib",
      "${prefix}/lib/libxslt.${lib_version}.dylib",
      "${prefix}/bin/xsltproc",
    ]
    $lib_path = "@rpath/libxslt.${lib_version}.dylib"
    $embedded_dir = "${prefix}/lib"

    vagrant_substrate::staging::darwin_rpath { $libxslt_paths:
      new_lib_path => $lib_path,
      remove_rpath => $embedded_dir,
      require => Autotools["libxslt"],
      subscribe => Autotools["libxslt"],
    }
  }

  if $kernel == 'Linux' {
    $libxslt_paths = [
      "${prefix}/bin/xsltproc",
      "${prefix}/lib/libxslt.so",
    ]

    vagrant_substrate::staging::linux_chrpath{ $libxslt_paths:
      require => Autotools["libxslt"],
      subscribe => Autotools["libxslt"],
    }
  }
}
