# == Class: libssh2
#
# This installs the libssh2 library from source.
#
class libssh2(
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $make_notify = undef,
  $prefix = params_lookup('prefix'),
) {
  require build_essential

  $source_filename  = "libssh2-1.7.0.tar.gz"
  $source_url = "http://www.libssh2.org/download/${source_filename}"
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
  wget::fetch { "libssh2":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-libssh2":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["libssh2"],
  }

  autotools { "libssh2":
    configure_flags  => "--prefix=${prefix} --disable-dependency-tracking --with-libssl-prefix=${prefix}",
    cwd              => $source_dir_path,
    environment      => $real_autotools_environment,
    install_sentinel => "${prefix}/lib/libssh2.a",
    make_notify      => $make_notify,
    make_sentinel    => "${source_dir_path}/.libs/libssh2.a",
    require          => Exec["untar-libssh2"],
  }

  if $kernel == 'Darwin' {
    $libssh2_paths = [
      "${prefix}/lib/libssh2.dylib",
      "${prefix}/lib/libssh2.${lib_version}.dylib",
    ]
    $lib_path = "@rpath/libssh2.${lib_version}.dylib"
    $embedded_dir = "${prefix}/lib"

    vagrant_substrate::staging::darwin_rpath { $libssh2_paths:
      new_lib_path => $lib_path,
      remove_rpath => $embedded_dir,
      require => Autotools["libssh2"],
      subscribe => Autotools["libssh2"],
    }
  }
}
