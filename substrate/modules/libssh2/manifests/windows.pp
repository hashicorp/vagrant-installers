define libssh2::windows(
  $file_cache_dir,
  $install_dir,
  $target_arch,
) {
  $libssh2_version = hiera("libssh2::version")

  # libssh2 variables
  $libssh2_filename = "libssh2-${libssh2_version}.zip"
  $libssh2_url = "http://github.com/libssh2/libssh2/archive/${libssh2_filename}"
  $libssh2_file_path = "${file_cache_dir}\\libssh2-${target_arch}.zip"
  $libssh2_dir_name = "libssh2-libssh2-${libssh2_version}"
  $libssh2_extract_to = "${file_cache_dir}\\${target_arch}"
  $libssh2_source_directory = "${libssh2_extract_to}\\${libssh2_dir_name}"

  $builder_path = "${libssh2_source_directory}\\builder.bat"
  $installer_path = "${libssh2_source_directory}\\installer.bat"

  download { "libssh2-${target_arch}":
    source => $libssh2_url,
    destination => $libssh2_file_path,
    file_cache_dir => $file_cache_dir,
  }

  exec { "libssh2-extract-dir-${target_arch}":
    command => "cmd /c mkdir \"${libssh2_extract_to}\"",
    creates => $libssh2_extract_to,
  }

  exec { "extract-libssh2-${target_arch}":
    command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${libssh2_file_path} -y",
    creates => $libssh2_source_directory,
    cwd => $libssh2_extract_to,
    require => [
      Download["libssh2-${target_arch}"],
      Exec["libssh2-extract-dir-${target_arch}"],
    ]
  }

  file { $builder_path:
    ensure => present,
    content => template("libssh2/builder.bat.erb"),
    require => [
      Exec["extract-libssh2-${target_arch}"],
    ],
  }

  file { $installer_path:
    ensure => present,
    content => template("libssh2/installer.bat.erb"),
    require => [
      Exec["extract-libssh2-${target_arch}"],
    ],
  }

  exec { "build-libssh2-${target_arch}":
    command => "cmd /c ${builder_path}",
    cwd => $libssh2_source_directory,
    require => [
      File[$builder_path],
    ],
  }

  exec { "install-libssh2-${target_arch}":
    command => "cmd /c ${installer_path}",
    cwd => $libssh2_source_directory,
    require => [
      Exec["build-libssh2-${target_arch}"],
      File[$installer_path],
    ],
  }
}