# == Class: openssl::install::darwin
#
# This compiles and installs OpenSSL on Darwin (Mac). This is a little
# trickier because we have to compile both a 32-bit and 64-bit version
# in order to properly make a universal binary.
#
class openssl::install::darwin {
  $autotools_environment = $openssl::autotools_environment
  $file_cache_dir        = $openssl::file_cache_dir
  $lib_version           = $openssl::lib_version
  $make_notify           = $openssl::make_notify
  $prefix                = $openssl::prefix
  $source_dir_path       = $openssl::source_dir_path

  $openssl_32_path = "${file_cache_dir}/openssl-32"
  $openssl_64_path = "${file_cache_dir}/openssl-64"

  exec { "nuke-openssl-64":
    command     => "rm -rf ${openssl_64_path}",
    refreshonly => true,
    subscribe   => Exec["untar-openssl"],
  }

  exec { "copy-openssl-64":
    command   => "cp -R ${source_dir_path} ${openssl_64_path}",
    creates   => $openssl_64_path,
    require   => [
      Exec["nuke-openssl-64"],
      Exec["untar-openssl"],
    ],
  }

  exec { "clean-openssl-64":
    command => "make clean",
    cwd     => $openssl_64_path,
    require => Exec["copy-openssl-64"],
  }

  # Note that we "install" the 64-bit version. This is just so that we
  # can get the headers and all that properly into the final directory.
  # We replace the libraries it would install with our own universal
  # binaries later in the process.
  autotools { "openssl":
    configure_file     => "./Configure",
    configure_flags    => "--prefix=${prefix} shared darwin64-x86_64-cc",
    configure_sentinel => "${openssl_64_path}/apps/CA.pl.bak",
    cwd                => $openssl_64_path,
    environment        => $autotools_environment,
    install            => true,
    install_sentinel   => "${prefix}/include/openssl/aes.h",
    make_notify        => $make_notify,
    make_sentinel      => "${openssl_64_path}/libssl.a",
    require            => Exec["clean-openssl-64"],
  }
}
