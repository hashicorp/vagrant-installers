# == Class: libgpg_error
#
# This installs libgpg-error from source.
class libgpg_error(
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $make_notify = undef,
  $prefix = params_lookup('prefix'),
) {
  require build_essential

  $libgpg_error_version  = hiera("libgpg_error::version")
  $source_filename  = "libgpg-error-${libgpg_error_version}.tar.bz2"
  $source_url = "https://gnupg.org/ftp/gcrypt/libgpg-error/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.bz2$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  $lib_version = inline_template("<%= @libgpg_error_version.split('.')[0,2].join('.') %>")

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
  wget::fetch { "libgpg_error":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-libgpg_error":
    command => "tar xjf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["libgpg_error"],
  }

  autotools { "libgpg_error":
    configure_flags  => "--prefix=${prefix} --enable-static",
    cwd              => $source_dir_path,
    environment      => $real_autotools_environment,
    install_sentinel => "${prefix}/lib/libgpg-error.a",
    make_notify      => $make_notify,
    make_sentinel    => "${source_dir_path}/src/.libs/libgpg-error.a",
    require          => Exec["untar-libgpg_error"],
  }
}
