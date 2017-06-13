class vagrant_substrate::staging {
  include vagrant_substrate

  $embedded_dir = $vagrant_substrate::embedded_dir
  $staging_dir  = $vagrant_substrate::staging_dir
  $goarch       = $vagrant_substrate::goarch
  $goos         = $vagrant_substrate::goos

  $exe = $goos ? {
    "windows" => ".exe",
    default   => "",
  }

  #------------------------------------------------------------------
  # OS-Specific
  #------------------------------------------------------------------
  case $kernel {
    'Darwin', 'Linux': { include vagrant_substrate::staging::posix }
    'windows': { include vagrant_substrate::staging::windows }
    default:   { fail("Unknown operating system to stage.") }
  }
}
