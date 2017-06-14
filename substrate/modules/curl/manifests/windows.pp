class curl::windows {
  $file_cache_dir  = $curl::file_cache_dir
  $install_dir     = $curl::install_dir
  $curl_version    = hiera("curl::version")
  $libssh2_version = hiera("libssh2::version")

  # curl variables
  curl_filename  = "curl-${curl_version}.zip"
  $curl_url = "http://curl.haxx.se/download/${curl_filename}"
  $curl_file_path = "${file_cache_dir}\\curl.zip"
  $curl_dir_name  = "curl-${curl_version}"
  $curl_extract_to = "${file_cache_dir}"
  $curl_source_directory = "${file_cache_dir}\\${curl_dir_name}

  # libssh2 variables
  $libssh2_filename = "libssh2-${libssh2_version}.zip"
  $libssh2_url = "http://github.com/libssh2/libssh2/archive/${libssh2_filename}"
  $libssh2_file_path = "${file_cache_dir}\\libssh2.zip"
  $libssh2_dir_name = "libssh2-libssh2-${libssh_version}"
  $libssh2_extract_to = "${file_cache_dir}"
  $libssh2_source_directory = "${file_cache_dir}\\${libssh2_extract_to}"

  $curl_builder_path = "${file_cache_dir}\\curl-builder.bat"

  file { $curl_file_path:
    source => $curl_url,
  }

  file { $libssh2_file_path:
    source => $libssh2_url,
  }

  file { $curl_builder_path:
    source => "puppet:///modules/curl/curl_builder.bat",
  }

  powershell { "extract-curl":
    content        => epp("curl/extract.epp", {
      "zip_path" => $curl_file_path, "install_dir" => $curl_extract_to}),
    creates        => $curl_extract_to,
    file_cache_dir => $file_cache_dir,
    require        => File[$curl_file_path],
  }

  powershell { "extract-libssh2":
    content        => epp("curl/extract.epp", {
      "zip_path" => $libssh2_file_path, "install_dir" => $libssh2_extract_to}),
    creates        => $libssh2_extract_to,
    file_cache_dir => $file_cache_dir,
    require        => File[$libssh2_file_path],
  }

  exec { "build-curl":
    command => "cmd.exe /c ${curl_builder_path}",
    require => [
      File[$curl_builder_path],
      Powershell["extract-curl"],
      Powershell["extract-libssh2"],
    ]
  }

  exec ( "install-curl":
  }
}
