# == Class: openssl::install::linux
#
# This compiles and installs OpenSSL on Linux
#
class openssl::install::linux {
  $autotools_environment = $openssl::autotools_environment
  $make_notify           = $openssl::make_notify
  $prefix                = $openssl::prefix
  $source_dir_path       = $openssl::source_dir_path

  autotools { "openssl":
    configure_file     => "config",
    configure_flags    => "--prefix=${prefix} shared",
    configure_sentinel => "${source_dir_path}/apps/CA.pl.bak",
    cwd                => $source_dir_path,
    environment        => $autotools_environment,
    install_sentinel   => "${prefix}/bin/openssl",
    make_notify        => $make_notify,
    make_sentinel      => "${source_dir_path}/libssl.a",
    require            => Exec["untar-openssl"],
  }
}
