class openssl(
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $prefix = params_lookup('prefix'),
) {
  require build_essential

  $source_filename  = "openssl-1.0.1c.tar.gz"
  $source_url = "http://www.openssl.org/source/${source_filename}"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  #------------------------------------------------------------------
  # Compile
  #------------------------------------------------------------------
  wget::fetch { "openssl":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-openssl":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["openssl"],
  }

  autotools { "openssl":
    configure_file     => "config",
    configure_flags    => "--prefix=${prefix} shared",
    configure_sentinel => "${source_dir_path}/Makefile.bak",
    cwd                => $source_dir_path,
    environment        => $autotools_environment,
    require            => Exec["untar-openssl"],
  }
}
