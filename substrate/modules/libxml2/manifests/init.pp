# == Class: libxml2
#
# This installs the libxml2 library from source.
#
class libxml2(
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $make_notify = undef,
  $prefix = params_lookup('prefix'),
) {
  require build_essential

  $source_filename  = "libxml2-2.9.4.tar.gz"
  $source_url = "ftp://xmlsoft.org/libxml2/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  $lib_version = "2"

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
  wget::fetch { "libxml2":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-libxml2":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["libxml2"],
  }

  autotools { "libxml2":
    configure_flags  => "--prefix=${prefix} --disable-dependency-tracking --without-python --without-lzma --with-zlib=${prefix}",
    cwd              => $source_dir_path,
    environment      => $real_autotools_environment,
    install_sentinel => "${prefix}/lib/libxml2.a",
    make_notify      => $make_notify,
    make_sentinel    => "${source_dir_path}/.libs/libxml2.a",
    require          => Exec["untar-libxml2"],
  }

  if $kernel == 'Darwin' {
    $libxml2_paths = [
      "${prefix}/lib/libxml2.dylib",
      "${prefix}/lib/libxml2.${lib_version}.dylib",
      "${prefix}/bin/xmlcatalog",
      "${prefix}/bin/xmllint",
    ]
    $lib_path = "@rpath/libxml2.${lib_version}.dylib"
    $embedded_dir = "${prefix}/lib"

    vagrant_substrate::staging::darwin_rpath { $libxml2_paths:
      new_lib_path => $lib_path,
      remove_rpath => $embedded_dir,
      require => Autotools["libxml2"],
      subscribe => Autotools["libxml2"],
    }
  }

  if $kernel == 'Linux' {
    $libxml2_paths = [
      "${prefix}/lib/libxml2.so",
      "${prefix}/bin/xmlcatalog",
      "${prefix}/bin/xmllint",
    ]

    vagrant_substrate::staging::linux_chrpath{ $libxml2_paths:
      require => Autotools["libxml2"],
      subscribe => Autotools["libxml2"],
    }
  }
}
