define zlib::windows(
  $file_cache_dir,
  $install_dir,
  $target_arch,
) {
  $zlib_version = hiera("zlib::version")

  # zlib variables
  $zlib_filename = "v${zlib_version}.zip"
  $zlib_url = "http://github.com/madler/zlib/archive/${zlib_filename}"
  $zlib_file_path = "${file_cache_dir}\\zlib-${target_arch}.zip"
  $zlib_dir_name = "zlib-${zlib_version}"
  $zlib_extract_to = "${file_cache_dir}\\${target_arch}"
  $zlib_source_directory = "${zlib_extract_to}\\${zlib_dir_name}"

  $builder_path = "${zlib_source_directory}\\builder.bat"
  $installer_path = "${zlib_source_directory}\\installer.bat"

  download { "zlib-${target_arch}":
    source => $zlib_url,
    destination => $zlib_file_path,
    file_cache_dir => $file_cache_dir,
  }

  exec { "zlib-extract-dir-${target_arch}":
    command => "cmd /c mkdir \"${zlib_extract_to}\"",
    creates => $zlib_extract_to,
  }

  exec { "extract-zlib-${target_arch}":
    command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${zlib_file_path} -y",
    creates => $zlib_source_directory,
    cwd => $zlib_extract_to,
    require => [
      Download["zlib-${target_arch}"],
      Exec["zlib-extract-dir-${target_arch}"],
    ]
  }

  file { $builder_path:
    ensure => present,
    content => template("zlib/builder.bat.erb"),
    require => [
      Exec["extract-zlib-${target_arch}"],
    ],
  }

  file { $installer_path:
    ensure => present,
    content => template("zlib/installer.bat.erb"),
    require => [
      Exec["extract-zlib-${target_arch}"],
    ],
  }

  exec { "build-zlib-${target_arch}":
    command => "cmd /c ${builder_path}",
    cwd => $zlib_source_directory,
    require => [
      File[$builder_path],
    ],
  }

  exec { "install-zlib-${target_arch}":
    command => "cmd /c ${installer_path}",
    cwd => $zlib_source_directory,
    require => [
      Exec["build-zlib-${target_arch}"],
    ],
  }
}