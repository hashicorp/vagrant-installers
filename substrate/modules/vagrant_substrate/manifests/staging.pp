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
    'Darwin', 'Linux', 'FreeBSD': { include vagrant_substrate::staging::posix }
    'windows': { include vagrant_substrate::staging::windows }
    default:   { fail("Unknown operating system to stage.") }
  }

  #------------------------------------------------------------------
  # Common
  #------------------------------------------------------------------
  $gemrc_path = "${embedded_dir}/etc/gemrc"

  file { $gemrc_path:
    content => template("vagrant_substrate/gemrc.erb"),
    mode    => "0644",
  }

  file { "${embedded_dir}/cacert.pem":
    source => "puppet:///modules/vagrant_substrate/cacert.pem",
    mode   => "0644",
  }

  # Unix bin file. We include this in Windows too in case mingw/cygwin
  file { "${staging_dir}/bin/vagrant${exe}":
    source  => "puppet:///modules/vagrant_substrate/launcher_${goos}_${goarch}${exe}",
    mode    => "0755",
  }
}
