# == Class: libffi
#
# Installs libffi.
#
class libffi (
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $make_notify = undef,
  $prefix = params_lookup('prefix'),
) {
  require build_essential

  $source_filename  = "libffi-3.2.1.tar.gz"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"
  $lib_version = "6"

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
  wget::fetch { "libffi":
    source      => "ftp://sourceware.org/pub/libffi/${source_filename}",
    destination => $source_file_path,
  }

  exec { "untar-libffi":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["libffi"],
  }

  # Note we use a custom make command here so we can have a make sentinel
  # of value to actually use. The files made by compiling libffi are hard to
  # know from Puppet, so this is the best way to do it, seemingly.
  autotools { "libffi":
    configure_flags  => "--prefix=${prefix} --disable-debug --disable-dependency-tracking",
    cwd              => $source_dir_path,
    environment      => $real_autotools_environment,
    install_sentinel => "${prefix}/lib/libffi.a",
    make_command     => "make && touch ${source_dir_path}/make_complete",
    make_notify      => $make_notify,
    make_sentinel    => "${source_dir_path}/make_complete",
    require          => Exec["untar-libffi"],
  }

  #------------------------------------------------------------------
  # Extra hacks
  #------------------------------------------------------------------
  # We need to move the headers out to a standard place so that things
  # can properly link against libffi. We do this by just making a symlink.
  file { "${prefix}/include/ffi.h":
    ensure  => link,
    target  => "../lib/${source_dir_name}/include/ffi.h",
    require => Autotools["libffi"],
  }

  file { "${prefix}/include/ffitarget.h":
    ensure  => link,
    target  => "../lib/${source_dir_name}/include/ffitarget.h",
    require => Autotools["libffi"],
  }

  if $kernel == 'Darwin' {
    $libffi_paths = [
      "${prefix}/lib/libffi.dylib",
      "${prefix}/lib/libffi.${lib_version}.dylib",
    ]
    $lib_path = "@rpath/libffi.${lib_version}.dylib"
    $embedded_dir = "${prefix}/lib"

    vagrant_substrate::staging::darwin_rpath { $libffi_paths:
      new_lib_path => $lib_path,
      remove_rpath => $embedded_dir,
      require => Autotools["libffi"],
      subscribe => Autotools["libffi"],
    }
  }

  if $kernel == 'Linux' {
    $libffi_paths = [
      "${prefix}/lib/libffi.so",
    ]

    vagrant_substrate::staging::linux_chrpath{ $libffi_paths:
      require => Autotools["libffi"],
      subscribe => Autotools["libffi"],
    }
  }
}
