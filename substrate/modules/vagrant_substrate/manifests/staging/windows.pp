class vagrant_substrate::staging::windows {
  include vagrant_substrate

  $cache_dir         = $vagrant_substrate::cache_dir
  $embedded_dir      = $vagrant_substrate::embedded_dir
  $staging_dir       = $vagrant_substrate::staging_dir
  $installer_version = $vagrant_substrate::installer_version

  $staging_dir_32   = "${staging_dir}\\x32"
  $staging_dir_64   = "${staging_dir}\\x64"

  $embedded_dir_32  = "${staging_dir_32}\\embedded"
  $embedded_dir_64  = "${staging_dir_64}\\embedded"

  $ruby_version      = hiera("ruby::version")
  $ruby_files_path   = "${cache_dir}\\ruby-files"
  $ruby_build_path   = "${cache_dir}\\ruby-build"
  $ruby_bash_builder = "${cache_dir}\\bash-builder.sh"

  $builder_path      = "${cache_dir}\\substrate_builder.sh"
  $builder_cwd       = "C:\\msys64\\home\\vagrant\\styrene"
  $builder_config    = "${builder_cwd}\\vagrant.cfg"

  $launcher_path     = "${cache_dir}\\launcher"

  $winpty_version        = hiera("vagrant_substrate::winpty_version")
  $winpty_cygwin_version = hiera("vagrant_substrate::winpty_cygwin_version")
  $winpty_msys2_version  = hiera("vagrant_substrate::winpty_msys2_version")

  file { $staging_dir_64:
    ensure => "directory",
    recurse => true,
  }

  file { $staging_dir_32:
    ensure => "directory",
    recurse => true,
  }

  file { $embedded_dir_64:
    ensure => "directory",
    recurse => true,
  }

  file { $embedded_dir_32:
    ensure => "directory",
    recurse => true,
  }

  file { "${embedded_dir_64}\\bin":
    ensure => "directory",
    recurse => true,
  }

  file { "${embedded_dir_32}\\bin":
    ensure => "directory",
    recurse => true,
  }

  file { "${embedded_dir_64}\\bin\\msys":
    ensure => "directory",
    recurse => true,
  }

  file { "${embedded_dir_64}\\bin\\cygwin":
    ensure => "directory",
    recurse => true,
  }

  file { "${embedded_dir_32}\\bin\\msys":
    ensure => "directory",
    recurse => true,
  }

  file { "${embedded_dir_32}\\bin\\cygwin":
    ensure => "directory",
    recurse => true,
  }

  file { $builder_path:
    content => template("vagrant_substrate/substrate_builder.sh.erb"),
  }

  file { $builder_config:
    content => template("vagrant_substrate/vagrant.cfg.erb"),
  }

  file { $ruby_files_path:
    source => "puppet:///modules/vagrant_substrate/windows-ruby-${ruby_version}",
    path => $ruby_files_path,
    recurse => true,
  }

  file { $ruby_bash_builder:
    content => template("vagrant_substrate/ruby-bash-builder.sh.erb")
  }

  powershell { "build-ruby":
    content => template("vagrant_substrate/windows_ruby_builder.ps1.erb"),
    file_cache_dir => $cache_dir,
    require => [
      File[$ruby_bash_builder],
      File[$ruby_files_path],
    ],
  }

  powershell { "build-substrate":
    content => template("vagrant_substrate/substrate_waiter.ps1.erb"),
    file_cache_dir => $cache_dir,
    require => [
      File[$builder_path],
      File[$builder_config],
      File[$embedded_dir_64],
      File[$embedded_dir_32],
      Powershell["build-ruby"],
    ],
  }

  file { $launcher_path:
    source => "puppet:///modules/vagrant_substrate/launcher",
    path => $launcher_path,
    recurse => true,
  }

  # ensure dependency is around
  exec { "install-osext":
    command => "cmd.exe /c \"C:\\Go\\bin\\go.exe get github.com/mitchellh/osext\"",
    environment => [
      "GOPATH=C:\\Windows\\Temp",
      "PATH=C:\\Go\\bin;C:\\Program Files\\Git\\bin;%PATH%",
    ],
  }

  # install launcher
  exec { "install-launcher-x64":
    command => "C:\\Go\\bin\\go.exe build -o \"${staging_dir_64}\\bin\\vagrant.exe\" main.go",
    cwd => $launcher_path,
    environment => [
      "GOPATH=C:\\Windows\\Temp",
    ],
    require => [
      File[$launcher_path],
      Exec["install-osext"],
      Powershell["build-substrate"],
    ],
  }

  exec { "install-launcher-x32":
    command => "C:\\Go\\bin\\go.exe build -o \"${staging_dir_32}\\bin\\vagrant.exe\" main.go",
    cwd => $launcher_path,
    environment => [
      "GOARCH=386",
    ],
    require => [
      File[$launcher_path],
      Exec["install-osext"],
      Powershell["build-substrate"],
    ],
  }

  file { "${embedded_dir_64}\\etc\\gemrc":
    content => template("vagrant_substrate/gemrc.erb"),
    mode    => "0644",
    recurse => true,
    require => [
      Powershell["build-substrate"],
    ],
  }

  file { "${embedded_dir_32}\\etc\\gemrc":
    content => template("vagrant_substrate/gemrc.erb"),
    recurse => true,
    mode    => "0644",
    require => [
      Powershell["build-substrate"],
    ],
  }

  file { "${embedded_dir_64}\\cacert.pem":
    source => "puppet:///modules/vagrant_substrate/cacert.pem",
    mode   => "0644",
    require => [
      Powershell["build-substrate"],
    ],
  }

  file { "${embedded_dir_32}\\cacert.pem":
    source => "puppet:///modules/vagrant_substrate/cacert.pem",
    mode   => "0644",
    require => [
      Powershell["build-substrate"],
    ],
  }

  # winpty installations #

  # Local paths
  $winpty_cygwin_32 = "${cache_dir}\\winpty_cygwin32.tar.gz"
  $winpty_cygwin_64 = "${cache_dir}\\winpty_cygwin64.tar.gz"
  $winpty_msys2_32 = "${cache_dir}\\winpty_msys2_32.tar.gz"
  $winpty_msys2_64 = "${cache_dir}\\winpty_msys2_64.tar.gz"
  $winpty_cygwin_32_tar = "${cache_dir}\\winpty_cygwin32.tar"
  $winpty_cygwin_64_tar = "${cache_dir}\\winpty_cygwin64.tar"
  $winpty_msys2_32_tar = "${cache_dir}\\winpty_msys2_32.tar"
  $winpty_msys2_64_tar = "${cache_dir}\\winpty_msys2_64.tar"

  # Remote package URLS
  $winpty_cygwin_32_url = "http://github.com/rprichard/winpty/releases/download/${winpty_version}/winpty-${winpty_version}-cygwin-${winpty_cygwin_version}-ia32.tar.gz"
  $winpty_cygwin_64_url = "http://github.com/rprichard/winpty/releases/download/${winpty_version}/winpty-${winpty_version}-cygwin-${winpty_cygwin_version}-x64.tar.gz"
  $winpty_msys2_32_url = "http://github.com/rprichard/winpty/releases/download/${winpty_version}/winpty-${winpty_version}-msys2-${winpty_msys2_version}-ia32.tar.gz"
  $winpty_msys2_64_url = "http://github.com/rprichard/winpty/releases/download/${winpty_version}/winpty-${winpty_version}-msys2-${winpty_msys2_version}-x64.tar.gz"

  # Cygwin - 32-bit
  download { "winpty_cygwin_32":
    source => $winpty_cygwin_32_url,
    destination => $winpty_cygwin_32,
    file_cache_dir => "C:\\Windows\\Temp",
  }

  exec { "gunzip-${winpty_cygwin_32}":
    command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${winpty_cygwin_32} -y",
    creates => $winpty_cygwin_32_tar,
    cwd => $cache_dir,
    require => [
      Download["winpty_cygwin_32"],
    ],
  }

  exec { "untar-${winpty_cygwin_32}":
    command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${winpty_cygwin_32_tar} -y",
    creates => "${cache_dir}\\winpty-${winpty_version}-cygwin-${winpty_cygwin_version}-ia32",
    cwd => $cache_dir,
    require => [
      Exec["gunzip-${$winpty_cygwin_32}"],
    ],
  }

  exec { "install-${winpty_cygwin_32}":
    command => "cmd /c \"move ${cache_dir}\\winpty-${winpty_version}-cygwin-${winpty_cygwin_version}-ia32\\bin\\* ${embedded_dir_32}\\bin\\cygwin\"",
    creates => "${embedded_dir_32}\\bin\\winpty-cygwin.exe",
    require => [
      File["${embedded_dir_32}\\bin\\cygwin"],
      Exec["untar-${$winpty_cygwin_32}"],
    ],
  }

  # Cygwin - 64-bit
  download { "winpty_cygwin_64":
    source => $winpty_cygwin_64_url,
    destination => $winpty_cygwin_64,
    file_cache_dir => "C:\\Windows\\Temp",
  }

  exec { "gunzip-${winpty_cygwin_64}":
    command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${winpty_cygwin_64} -y",
    creates => $winpty_cygwin_64_tar,
    cwd => $cache_dir,
    require => [
      Download["winpty_cygwin_64"],
    ],
  }

  exec { "untar-${winpty_cygwin_64}":
    command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${winpty_cygwin_64_tar} -y",
    creates => "${cache_dir}\\winpty-${winpty_version}-cygwin-${winpty_cygwin_version}-x64",
    cwd => $cache_dir,
    require => [
      Exec["gunzip-${$winpty_cygwin_64}"],
    ],
  }

  exec { "install-${winpty_cygwin_64}":
    command => "cmd /c \"move ${cache_dir}\\winpty-${winpty_version}-cygwin-${winpty_cygwin_version}-x64\\bin\\* ${embedded_dir_64}\\bin\\cygwin\"",
    creates => "${embedded_dir_64}\\bin\\winpty-cygwin.exe",
    require => [
      File["${embedded_dir_64}\\bin\\cygwin"],
      Exec["untar-${$winpty_cygwin_64}"],
    ],
  }

  # msys2 32-bit
  download { "winpty_msys2_32":
    source => $winpty_msys2_32_url,
    destination => $winpty_msys2_32,
    file_cache_dir => "C:\\Windows\\Temp",
  }

  exec { "gunzip-${winpty_msys2_32}":
    command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${winpty_msys2_32} -y",
    creates => $winpty_msys2_32_tar,
    cwd => $cache_dir,
    require => [
      Download["winpty_msys2_32"],
    ],
  }

  exec { "untar-${winpty_msys2_32}":
    command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${winpty_msys2_32_tar} -y",
    cwd => $cache_dir,
    creates => "${cache_dir}\\winpty-${winpty_version}-msys2-${winpty_msys2_version}-ia32",
    require => [
      Exec["gunzip-${$winpty_msys2_32}"],
    ],
  }

  exec { "install-${winpty_msys2_32}":
    command => "cmd /c \"move ${cache_dir}\\winpty-${winpty_version}-msys2-${winpty_msys2_version}-ia32\\bin\\* ${embedded_dir_32}\\bin\\msys\"",
    creates => "${embedded_dir_32}\\bin\\winpty-msys2.exe",
    require => [
      File["${embedded_dir_32}\\bin\\msys"],
      Exec["untar-${$winpty_msys2_32}"],
    ],
  }

  # msys2 64-bit
  download { "winpty_msys2_64":
    source => $winpty_msys2_64_url,
    destination => $winpty_msys2_64,
    file_cache_dir => "C:\\Windows\\Temp",
  }

  exec { "gunzip-${winpty_msys2_64}":
    command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${winpty_msys2_64} -y",
    creates => $winpty_msys2_64_tar,
    cwd => $cache_dir,
    require => [
      Download["winpty_msys2_64"],
    ],
  }

  exec { "untar-${winpty_msys2_64}":
    command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${winpty_msys2_64_tar} -y",
    creates => "${cache_dir}\\winpty-${winpty_version}-msys2-${winpty_msys2_version}-x64",
    cwd => $cache_dir,
    require => [
      Exec["gunzip-${$winpty_msys2_64}"],
    ],
  }

  exec { "install-${winpty_msys2_64}":
    command => "cmd /c \"move ${cache_dir}\\winpty-${winpty_version}-msys2-${winpty_msys2_version}-x64\\bin\\* ${embedded_dir_64}\\bin\\msys\"",
    creates => "${embedded_dir_64}\\bin\\winpty-msys.exe",
    require => [
      File["${embedded_dir_64}\\bin\\msys"],
      Exec["untar-${$winpty_msys2_64}"],
    ],
  }

  class { "rubyencoder::loaders":
    path => $staging_dir,
    require => [
      Powershell["build-substrate"],
    ],
  }
}
