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

  #------------------------------------------------------------------
  # Compile 32-bit
  #------------------------------------------------------------------
  exec { "nuke-openssl-32":
    command     => "rm -rf ${openssl_32_path}",
    refreshonly => true,
    subscribe   => Exec["untar-openssl"],
  }

  exec { "copy-openssl-32":
    command   => "cp -R ${source_dir_path} ${openssl_32_path}",
    creates   => $openssl_32_path,
    require   => [
      Exec["nuke-openssl-32"],
      Exec["untar-openssl"],
    ],
  }

  exec { "clean-openssl-32":
    command => "make clean",
    cwd     => $openssl_32_path,
    require => Exec["copy-openssl-32"],
  }

  autotools { "openssl-32":
    configure_file     => "./Configure",
    configure_flags    => "--prefix=${prefix} shared darwin-i386-cc",
    configure_sentinel => "${openssl_32_path}/apps/CA.pl.bak",
    cwd                => $openssl_32_path,
    environment        => $autotools_environment,
    install            => false,
    make_notify        => $make_notify,
    make_sentinel      => "${openssl_32_path}/libssl.a",
    require            => Exec["clean-openssl-32"],
  }

  #------------------------------------------------------------------
  # Compile 64-bit
  #------------------------------------------------------------------
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
  autotools { "openssl-64":
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

  #------------------------------------------------------------------
  # Create the Universal Binary
  #
  # OpenSSL has no built-in support for creating the universal binary
  # of the library so we have to take both the 32-bit and 64-bit versions
  # and then lipo them together.
  #------------------------------------------------------------------
  $final_directory      = "${file_cache_dir}/openssl-final"
  $final_libssl_path    = "${prefix}/lib/libssl.${lib_version}.dylib"

  exec { "nuke-openssl-final":
    command     => "rm -rf ${final_directory}",
    refreshonly => true,
    subscribe   => Exec["untar-openssl"],
  }

  util::recursive_directory { $final_directory:
    require => Exec["nuke-openssl-final"],
  }

  openssl::install::darwin_lipo { ["libcrypto", "libssl"]:
    final_directory => $final_directory,
    lib_version     => $lib_version,
    path_32         => $openssl_32_path,
    path_64         => $openssl_64_path,
    prefix_dir      => $prefix,
    require         => [
      Autotools["openssl-32"],
      Autotools["openssl-64"],
      Util::Recursive_directory[$final_directory],
    ],
  }

  # For libssl, we need to change the rpath to the libcrypto lib
  # so that it can properly find it in our embedded setup.
  $old_rpath = "${prefix}/lib/libcrypto.${lib_version}.dylib"
  $new_rpath = "@rpath/libcrypto.${lib_version}.dylib"
  exec { "libssl-rpath":
    command     => "install_name_tool -change ${old_rpath} ${new_rpath} ${final_libssl_path}",
    refreshonly => true,
    require     => Openssl::Install::Darwin_lipo["libssl"],
    subscribe   => Exec["move-dylib-libssl"],
  }
}
