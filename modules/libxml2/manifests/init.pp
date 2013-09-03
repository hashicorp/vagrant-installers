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

  $source_filename  = "libxml2-2.9.0.tar.gz"
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

  patch { "patch-libxml2-001":
    content     => template('libxml2/patch_001.diff'),
    prefixlevel => "1",
    cwd         => $source_dir_path,
    require     => Exec["untar-libxml2"],
    before      => Autotools["libxml2"],
  }

  patch { "patch-libxml2-002":
    content     => template('libxml2/patch_002.diff'),
    prefixlevel => "1",
    cwd         => $source_dir_path,
    require     => Exec["untar-libxml2"],
    before      => Autotools["libxml2"],
  }

  autotools { "libxml2":
    configure_flags  => "--prefix=${prefix} --disable-dependency-tracking --without-python",
    cwd              => $source_dir_path,
    environment      => $real_autotools_environment,
    install_sentinel => "${prefix}/lib/libxml2.a",
    make_notify      => $make_notify,
    make_sentinel    => "${source_dir_path}/.libs/libxml2.a",
    require          => Exec["untar-libxml2"],
  }
}
