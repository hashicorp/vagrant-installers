# == Class: libiconv
#
# This installs libiconv from source.
#
class libiconv(
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $make_notify = undef,
  $prefix = params_lookup('prefix'),
) {
  require build_essential

  $libiconv_version = hiera("libiconv::version")
  $source_filename  = "libiconv-${libiconv_version}.tar.gz"
  $source_url = "http://mirrors.kernel.org/gnu/libiconv/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  $lib_iconv_version = "2"
  $lib_charset_version = "1"

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
  wget::fetch { "libiconv":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-libiconv":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["libiconv"],
  }

  exec { "remove-getc-warning":
    command => "sed -i -e 's/^_GL_WARN_ON_USE.*gets.*security.*fgets.*$//' stdio.in.h",
    cwd => "${source_dir_path}/srclib",
    require => Exec["untar-libiconv"]
  }

  autotools { "libiconv":
    configure_flags  => "--prefix=${prefix} --disable-dependency-tracking",
    cwd              => $source_dir_path,
    environment      => $real_autotools_environment,
    install_sentinel => "${prefix}/lib/libiconv.a",
    make_notify      => $make_notify,
    make_sentinel    => "${source_dir_path}/lib/.libs/iconv.o",
    require          => Exec["untar-libiconv"],
  }
}
