class curl::windows {
  $file_cache_dir = $curl::file_cache_dir
  $install_dir    = $curl::install_dir

  $source_file_path = "${file_cache_dir}\\curl.zip"

  file { $source_file_path:
    source => "puppet:///modules/curl/windows.zip",
  }

  powershell { "extract-curl":
    content => template("curl/extract.erb"),
    creates => "${install_dir}/curl.exe",
    require => File[$source_file_path],
  }
}
