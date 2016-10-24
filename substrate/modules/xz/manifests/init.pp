# == Class: libxml2
#
# This installs the libxml2 library from source.
#
class xz(
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $make_notify = undef,
  $prefix = params_lookup('prefix'),
) {
  require build_essential

  $source_filename  = "xz-5.2.1.tar.gz"
  $source_url = "http://tukaani.org/xz/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  $lib_version = "5"

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
  wget::fetch { "xz":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-xz":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["xz"],
  }

  autotools { "xz":
    configure_flags  => "--prefix=${prefix} --disable-xz --disable-xzdec --disable-dependency-tracking --disable-lzmadec --disable-lzmainfo --disable-lzma-links --disable-scripts",
    cwd              => $source_dir_path,
    environment      => $real_autotools_environment,
    install_sentinel => "${prefix}/lib/liblzma.a",
    make_notify      => $make_notify,
    make_sentinel    => "${source_dir_path}/liblzma/.libs/liblzma.a",
    require          => Exec["untar-xz"],
  }

  if $kernel == 'Darwin' {
    $libxz_paths = [
      "${prefix}/lib/liblzma.dylib",
      "${prefix}/lib/liblzma.${lib_version}.dylib",
    ]
    $lib_path = "@rpath/liblzma.${lib_version}.dylib"
    $embedded_dir = "${prefix}/lib"

    vagrant_substrate::staging::darwin_rpath { $libxz_paths:
      new_lib_path => $lib_path,
      remove_rpath => $embedded_dir,
      require => Autotools["xz"],
      subscribe => Autotools["xz"],
    }
  }
}
