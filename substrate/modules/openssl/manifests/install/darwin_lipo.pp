# == Define: openssl::install:darwin_lipo
#
# A helper to lipo libraries together. This is used only by the OpenSSL
# Darwin installer, and this definition just removes a lot of duplication.
#
define openssl::install::darwin_lipo(
  $final_directory,
  $lib=$name,
  $lib_version,
  $path_32,
  $path_64,
  $prefix_dir,
) {
  $lib_filename      = "${lib}.${lib_version}.dylib"
  $lib32_dylib_path  = "${path_32}/${lib_filename}"
  $lib64_dylib_path  = "${path_64}/${lib_filename}"
  $lib32_static_path = "${path_32}/${lib}.a"
  $lib64_static_path = "${path_64}/${lib}.a"
  $final_dylib       = "${final_directory}/${lib_filename}"
  $final_static      = "${final_directory}/${lib}.a"
  $prefix_dylib      = "${prefix_dir}/lib/${lib_filename}"
  $prefix_static      = "${prefix_dir}/lib/${lib}.a"

  exec { "lipo-${lib}-dylib":
    command => "lipo -create ${lib32_dylib_path} ${lib64_dylib_path} -output ${final_dylib}",
    creates => $final_dylib,
  }

  exec { "lipo-${lib}-static":
    command => "lipo -create ${lib32_static_path} ${lib64_static_path} -output ${final_static}",
    creates => $final_static,
  }

  exec { "ranlib-${lib}-static":
    command     => "ranlib ${final_static}",
    refreshonly => true,
    subscribe   => Exec["lipo-${lib}-static"],
  }

  exec { "${lib}-id":
    command     => "install_name_tool -id @rpath/${lib_filename} ${final_dylib}",
    refreshonly => true,
    subscribe   => Exec["lipo-${lib}-dylib"],
  }

  exec { "move-dylib-${lib}":
    command     => "cp ${final_dylib} ${prefix_dylib}",
    require     => Exec["${lib}-id"],
    subscribe   => Exec["lipo-${lib}-dylib"],
  }

  exec { "move-static-${lib}":
    command => "cp ${final_static} ${prefix_static}",
    require     => Exec["ranlib-${lib}-static"],
    subscribe   => Exec["lipo-${lib}-static"],
  }
}
