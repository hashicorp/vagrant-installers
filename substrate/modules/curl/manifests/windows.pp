define curl::windows(
  $file_cache_dir,
  $install_dir,
  $target_arch,
) {
  $curl_version    = hiera("curl::version")

  # curl variables
  $curl_underscore_version = inline_template("<%= @curl_version.tr('.', '_') %>")
  $curl_filename  = "curl-${curl_version}.zip"
  $curl_url = "https://github.com/curl/curl/releases/download/curl-${curl_underscore_version}/${curl_filename}"
  $curl_file_path = "${file_cache_dir}\\curl-${target_arch}.zip"
  $curl_dir_name  = "curl-${curl_version}"
  $curl_extract_to = "${file_cache_dir}\\${target_arch}"
  $curl_source_directory = "${curl_extract_to}\\${curl_dir_name}"

  $curl_builder_path = "${curl_source_directory}\\winbuild\\curl-builder.bat"
  $curl_installer_path = "${curl_source_directory}\\curl-installer.bat"

  download { "curl-${target_arch}":
    source => $curl_url,
    destination => $curl_file_path,
    file_cache_dir => $file_cache_dir,
  }

  exec { "curl-extract-dir-${target_arch}":
    command => "cmd /c mkdir \"${curl_extract_to}\"",
    creates => $curl_extract_to,
  }

  file { $curl_builder_path:
    content => template("curl/builder.bat.erb"),
    require => [
      Exec["extract-curl-${target_arch}"],
    ],
  }

  file { $curl_installer_path:
    content => template("curl/installer.bat.erb"),
    require => [
      Exec["extract-curl-${target_arch}"],
    ],
  }

  exec { "extract-curl-${target_arch}":
    command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${curl_file_path} -y",
    creates => $curl_source_directory,
    cwd => "${file_cache_dir}\\${target_arch}",
    require => [
      Download["curl-${target_arch}"],
      Exec["curl-extract-dir-${target_arch}"],
    ],
  }

  zlib::windows { $target_arch:
    install_dir => "${curl_source_directory}\\deps",
    file_cache_dir => $file_cache_dir,
    target_arch => $target_arch,
    require => [
      Exec["extract-curl-${target_arch}"],
    ],
  }

  libssh2::windows { $target_arch:
    install_dir => "${curl_source_directory}\\deps",
    file_cache_dir => $file_cache_dir,
    target_arch => $target_arch,
    require => [
      Exec["extract-curl-${target_arch}"],
    ],
  }

  exec { "build-curl-${target_arch}":
    command => "cmd.exe /c ${curl_builder_path}",
    cwd => "${curl_source_directory}\\winbuild",
    require => [
      File[$curl_builder_path],
      Exec["extract-curl-${target_arch}"],
      Libssh2::Windows[$target_arch],
      Zlib::Windows[$target_arch],
    ]
  }

  exec { "install-curl-${target_arch}":
    command => "cmd.exe /c ${curl_installer_path}",
    cwd => $curl_source_directory,
    require => [
      Exec["build-curl-${target_arch}"],
      File[$curl_installer_path],
    ]
  }
}
