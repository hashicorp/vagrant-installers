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

  $libssl_path = "${prefix}/lib/libssl.${lib_version}.dylib"
  $libssl_stub_path = "${prefix}/lib/libssl.dylib"
  $new_ssl_rpath = "@rpath/libssl.${lib_version}.dylib"
  $libcrypto_path = "${prefix}/lib/libcrypto.${lib_version}.dylib"
  $libcrypto_stub_path = "${prefix}/lib/libcrypto.dylib"
  $new_crypto_rpath = "@rpath/libcrypto.${lib_version}.dylib"
  $openssl_path = "${prefix}/bin/openssl"
  $embedded_libdir = "${prefix}/lib"

  vagrant_substrate::staging::darwin_rpath { [$libcrypto_path, $libcrypto_stub_path]:
    new_lib_path => $new_crypto_rpath,
    remove_rpath => $embedded_libdir,
    require => Autotools["openssl"],
    subscribe => Autotools["openssl"],
  }

  vagrant_substrate::staging::darwin_rpath { $libssl_path:
    change_install_names => {
      libssl_crypto => {
        original => $libcrypto_path,
        replacement => $new_crypto_rpath
      },
    },
    new_lib_path => $new_ssl_rpath,
    remove_rpath => $embedded_libdir,
    require => Autotools["openssl"],
    subscribe => Autotools["openssl"],
  }

  vagrant_substrate::staging::darwin_rpath { $libssl_stub_path:
    change_install_names => {
      libssl_crypto_stub => {
        original => $libcrypto_path,
        replacement => $new_crypto_rpath
      },
    },
    new_lib_path => $new_ssl_rpath,
    remove_rpath => $embedded_libdir,
    require => Autotools["openssl"],
    subscribe => Autotools["openssl"],
  }


  vagrant_substrate::staging::darwin_rpath { $openssl_path:
    change_install_names => {
      openssl_libssl => {
        original => $libcrypto_path,
        replacement => $new_crypto_rpath
      },
      openssl_libcrypto => {
        original => $libssl_path,
        replacement => $new_ssl_rpath
      },
    },
    new_lib_path => $openssl_path,
    remove_rpath => $embedded_libdir,
    require => Autotools["openssl"],
    subscribe => Autotools["openssl"],
  }
}
