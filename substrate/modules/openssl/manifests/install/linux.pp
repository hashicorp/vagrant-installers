# == Class: openssl::install::linux
#
# This compiles and installs OpenSSL on Linux
#
class openssl::install::linux {
  $autotools_environment = $openssl::autotools_environment
  $make_notify           = $openssl::make_notify
  $prefix                = $openssl::prefix
  $source_dir_path       = $openssl::source_dir_path
  $installation_dir      = hiera("installation_dir")

  $lib_version = "1"

  autotools { "openssl":
    configure_file     => "config",
    configure_flags    => "--prefix=${prefix} --openssldir=${installation_dir}/embedded shared",
    configure_sentinel => "${source_dir_path}/apps/CA.pl.bak",
    cwd                => $source_dir_path,
    environment        => $autotools_environment,
    install_sentinel   => "${prefix}/bin/openssl",
    make_notify        => $make_notify,
    make_sentinel      => "${source_dir_path}/libssl.a",
    require            => Exec["untar-openssl"],
  }

  $libopenssl_paths = [
    "${prefix}/lib/libssl.so",
    "${prefix}/lib/libcrypto.so",
  ]

  vagrant_substrate::staging::linux_chrpath{ $libopenssl_paths:
    require => Autotools["openssl"],
    subscribe => Autotools["openssl"],
  }

  vagrant_substrate::staging::linux_chrpath{ "${prefix}/bin/openssl":
    new_rpath => '$ORIGIN/../lib',
    require => Autotools["openssl"],
    subscribe => Autotools["openssl"],
  }
}
