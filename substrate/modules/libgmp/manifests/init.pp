# == Class: libgmp
#
# This installs libgmp from source.
class libgmp(
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $make_notify = undef,
  $prefix = params_lookup('prefix'),
) {
  require build_essential

  $libgmp_version  = hiera("libgmp::version")
  $source_filename  = "gmp-${libgmp_version}.tar.bz2"
  $source_url = "https://ftp.gnu.org/gnu/gmp/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.bz2$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  $lib_version = inline_template("<%= @libgmp_version.split('.')[0,2].join('.') %>")

  if "64" in architecture {
    $abi_arch = "64"
  } else {
    $abi_arch = "32"
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

  # Merge our environments.
  $real_autotools_environment = autotools_merge_environments(
    $autotools_environment, $extra_autotools_environment)

  #------------------------------------------------------------------
  # Compile
  #------------------------------------------------------------------
  wget::fetch { "libgmp":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-libgmp":
    command => "tar xvjf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["libgmp"],
  }

  autotools { "libgmp":
    configure_flags  => "--prefix=${prefix} ABI=${abi_arch}",
    cwd              => $source_dir_path,
    environment      => $real_autotools_environment,
    install_sentinel => "${prefix}/lib/libgmp.a",
    make_notify      => $make_notify,
    make_sentinel    => "${source_dir_path}/src/.libs/libgmp.a",
    require          => Exec["untar-libgmp"],
  }

  if $kernel == 'Darwin' {
    $libgmp_paths = [
      "${prefix}/lib/libgmp.dylib",
    ]
    $lib_path = "@rpath/libgmp-${lib_version}.dylib"
    $embedded_dir = "${prefix}/lib"

    vagrant_substrate::staging::darwin_rpath { $libgmp_paths:
      new_lib_path => $lib_path,
      remove_rpath => $embedded_dir,
      require => Autotools["libgmp"],
      subscribe => Autotools["libgmp"],
    }
  }

  if $kernel == 'Linux' {
    $libgmp_paths = [
      "${prefix}/lib/libgmp.so",
    ]

    vagrant_substrate::staging::linux_chrpath{ $libgmp_paths:
      require => Autotools["libgmp"],
      subscribe => Autotools["libgmp"],
    }
  }
}
