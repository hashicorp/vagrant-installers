class vagrant_substrate::staging::windows {
  include vagrant_substrate

  $cache_dir         = $vagrant_substrate::cache_dir
  $embedded_dir      = $vagrant_substrate::embedded_dir
  $staging_dir       = $vagrant_substrate::staging_dir
  $installer_version = $vagrant_substrate::installer_version

  #------------------------------------------------------------------
  # Extra directories
  #------------------------------------------------------------------
  # For GnuForWin32 stuff
  $gnuwin32_dir = "${embedded_dir}\\gnuwin32"
  util::recursive_directory { $gnuwin32_dir: }

  #------------------------------------------------------------------
  # Dependencies
  #------------------------------------------------------------------
  class { "bsdtar":
    file_cache_dir => $cache_dir,
    install_dir    => $gnuwin32_dir,
    require        => Util::Recursive_Directory[$gnuwin32_dir],
  }

  class { "curl":
    file_cache_dir => $cache_dir,
    install_dir    => "${embedded_dir}\\bin",
  }

  class { "ruby::windows":
    file_cache_dir => $cache_dir,
    install_dir    => $embedded_dir,
  }

  class { "rubyencoder::loaders":
    path => $embedded_dir,
  }

  #------------------------------------------------------------------
  # Bin wrappers
  #------------------------------------------------------------------
  # EXE launcher for CMD.exe
  file { "${staging_dir}/bin/vagrant.exe":
    source  => "puppet:///modules/vagrant_substrate/vagrant.exe",
  }
}
