class atlas_upload_cli($install_path) {
  $version = "0.2.0"

  $goos = inline_template("<%= @kernel.downcase %>")
  if $goos == "windows" {
    $goarch = "386"
  } else {
    $goarch = $hardwaremodel ? {
      "i686"   => "386",
      "x86_64" => "amd64",
      "x64"    => "amd64",
    }
  }

  $source_filename  = "atlas-upload-cli_${version}_${goos}_${goarch}"
  $source_suffix = $kernel ? {
    "windows" => ".exe",
    default   => "",
  }

  file { $install_path:
    source => "puppet:///modules/atlas_upload_cli/${source_filename}/atlas-upload${source_suffix}",
  }
}
