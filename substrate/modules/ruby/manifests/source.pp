# == Class: ruby::source
#
# This compiles Ruby from source.
#
class ruby::source(
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $make_notify = undef,
  $prefix = params_lookup('prefix'),
) {
  require build_essential

  $source_filename  = "ruby-2.2.5.tar.gz"
  $source_url = "https://cache.ruby-lang.org/pub/ruby/2.2/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  $lib_short_version = "2.2"
  $lib_long_version = "2.2.0"

  if $operatingsystem == 'Darwin' {
    $extra_configure_flags = ' --with-arch=x86_64'
  }

  # OS-specific environment vars
  if $operatingsystem == 'Darwin' {
    $os_autotools_environment = {
      "LDFLAGS" => "-Wl,-rpath,${prefix}/lib",
    }
  } else {
    $os_autotools_environment = {}
  }


  # Ruby needs this include path on the include path so that
  # it will properly compile.
  $extra_autotools_environment = {
    "CFLAGS" => "-I${source_dir_path}/include",
  }

  $real_autotools_environment = autotools_merge_environments(
    $autotools_environment, $extra_autotools_environment, $os_autotools_environment)

  #------------------------------------------------------------------
  # Resetter
  #------------------------------------------------------------------
  # This is an exec that will "reset" Ruby so that it is recompiled.
  # This should be notified from outside of the Ruby class.
  exec { "reset-ruby":
    command     => "rm -rf ${source_dir_path}",
    refreshonly => true,
    before      => Exec["untar-ruby"],
  }

  #------------------------------------------------------------------
  # Compile
  #------------------------------------------------------------------
  # We use --insecure below because the older systems we run on don't
  # have the CA certificates. We really need to fix this.
  exec { "download-ruby":
    command => "curl --insecure -o ${source_file_path} ${source_url}",
    creates => $source_file_path,
    timeout => 1200,
  }

  exec { "untar-ruby":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Exec["download-ruby"],
  }

  autotools { "ruby":
    configure_flags  => "--prefix=${prefix} --disable-debug --disable-dependency-tracking --disable-install-doc --enable-shared --with-opt-dir=${prefix} --enable-load-relative${extra_configure_flags}",
    cwd              => $source_dir_path,
    environment      => $real_autotools_environment,
    install_sentinel => "${prefix}/bin/ruby",
    make_notify      => $make_notify,
    make_sentinel    => "${source_dir_path}/ruby",
    require          => Exec["untar-ruby"],
  }

  if $operatingsystem == 'Darwin' {
    file { "${prefix}/include/ruby-2.2.0/x86_64-darwin15":
      ensure  => link,
      target  => "universal-darwin15",
      require => Autotools["ruby"],
    }
  }

  # On Darwin we have to clean up some paths
  if $kernel == 'Darwin' {
    $libruby_paths = [
      "${prefix}/lib/libruby.dylib",
      "${prefix}/lib/libruby.${lib_short_version}.dylib",
      "${prefix}/lib/libruby.${lib_long_version}.dylib",
    ]
    $lib_path = "@rpath/libruby.${lib_long_version}.dylib"
    $original_lib_path = "@executable_path/../lib/libruby.${lib_long_version}.dylib"
    $embedded_dir = "${prefix}/lib"

    vagrant_substrate::staging::darwin_rpath { $libruby_paths:
      new_lib_path => $lib_path,
      remove_rpath => $embedded_dir,
      require => Autotools["ruby"],
      subscribe => Autotools["ruby"],
    }

    vagrant_substrate::staging::darwin_rpath { "${prefix}/bin/ruby":
      change_install_names => {
        libruby => {
          original => $original_lib_path,
          replacement => $lib_path,
        },
      },
      new_lib_path => $lib_path,
      remove_rpath => $embedded_dir,
      require => Autotools["ruby"],
      subscribe => Autotools["ruby"],
    }

    exec { "remove-ruby-bundle-rpaths":
      command     => "find ${prefix}/lib/ruby -type f -name '*.bundle' -exec install_name_tool -delete_rpath ${embedded_dir} {} \\;",
      refreshonly => true,
      require     => Autotools["ruby"],
      subscribe   => Autotools["ruby"],
    }

    exec { "modify-ruby-bundle-link-names":
      command     => "find ${prefix}/lib/ruby -type f -name '*.bundle' -exec install_name_tool -change ${original_lib_path} ${lib_path} {} \\;",
      refreshonly => true,
      require     => Autotools["ruby"],
      subscribe   => Autotools["ruby"],
    }
  }
}
