# == Class: libgcrypt
#
# This installs libgcrypt from source.
class libgcrypt(
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $make_notify = undef,
  $prefix = params_lookup('prefix'),
) {
  require build_essential

  $libgcrypt_version  = hiera("libgcrypt::version")
  $source_filename  = "libgcrypt-${libgcrypt_version}.tar.bz2"
  $source_url = "https://gnupg.org/ftp/gcrypt/libgcrypt/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.bz2$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  $lib_version = inline_template("<%= @libgcrypt_version.split('.')[0,2].join('.') %>")

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
  wget::fetch { "libgcrypt":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-libgcrypt":
    command => "tar xjf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["libgcrypt"],
  }

  autotools { "libgcrypt":
    configure_flags  => "--prefix=${prefix} --enable-static --with-libgpg-error-prefix=${prefix}",
    cwd              => $source_dir_path,
    environment      => $real_autotools_environment,
    install_sentinel => "${prefix}/lib/libgcrypt.a",
    make_notify      => $make_notify,
    make_sentinel    => "${source_dir_path}/src/.libs/libgcrypt.a",
    require          => Exec["untar-libgcrypt"],
  }

  if $kernel == 'Darwin' {
    $libgcrypt_paths = [
      "${prefix}/lib/libgcrypt.dylib",
    ]
    $lib_path = "@rpath/libgcrypt-${lib_version}.dylib"
    $embedded_dir = "${prefix}/lib"

    vagrant_substrate::staging::darwin_rpath { $libgcrypt_paths:
      new_lib_path => $lib_path,
      remove_rpath => $embedded_dir,
      require => Autotools["libgcrypt"],
      subscribe => Autotools["libgcrypt"],
    }
  }

  if $kernel == 'Linux' {
    $libgcrypt_paths = [
      "${prefix}/lib/libgcrypt.so",
    ]

    vagrant_substrate::staging::linux_chrpath{ $libgcrypt_paths:
      require => Autotools["libgcrypt"],
      subscribe => Autotools["libgcrypt"],
    }
  }
}
