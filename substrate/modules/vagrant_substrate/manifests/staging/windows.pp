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
  $ruby_lib_version  = inline_template("<%= @ruby_version.split('.').slice(0,2).join('.') %>.0")
  $ruby_package_name = inline_template("ruby<%= @ruby_version.split('.')[0,2].join %>")

  $builder_path      = "${cache_dir}\\substrate_builder.sh"
  $builder_cwd       = "C:\\msys64\\home\\vagrant\\styrene"
  $builder_config    = "${builder_cwd}\\vagrant.cfg"

  $launcher_path     = "${cache_dir}\\launcher"

  $winssh_version = hiera("vagrant_substrate::winssh_version")

  # TODO: Remove these after curl upgrade
  $curl_files_path   = "${cache_dir}\\curl-files"
  $curl_build_path   = "${cache_dir}\\curl-build"
  $curl_bash_builder = "${cache_dir}\\curl-bash-builder.sh"

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

  file { $curl_files_path:
    source => "puppet:///modules/vagrant_substrate/windows-curl",
    path => $curl_files_path,
    recurse => true,
  }

  file { $curl_bash_builder:
    content => template("vagrant_substrate/curl-bash-builder.sh.erb")
  }

  powershell { "build-curl":
    content => template("vagrant_substrate/windows_curl_builder.ps1.erb"),
    file_cache_dir => $cache_dir,
    require => [
      File[$curl_bash_builder],
      File[$curl_files_path],
      Powershell["build-ruby"],
    ],
  }

  powershell { "build-substrate":
    content => template("vagrant_substrate/substrate_waiter.ps1.erb"),
    file_cache_dir => $cache_dir,
    require => [
      File[$builder_path],
      File[$builder_config],
      Powershell["build-ruby"],
      Powershell["build-curl"],
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

  # NOTE: Currently disabled until vagrant supports required key file permission updates
  # Install Win32-OpenSSH
  # $winssh32_url = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v${winssh_version}/OpenSSH-Win32.zip"
  # $winssh32_path = "${cache_dir}\\winssh32.zip"

  # $winssh64_url = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v${winssh_version}/OpenSSH-Win64.zip"
  # $winssh64_path = "${cache_dir}\\winssh64.zip"

  # download { "winssh-32":
  #   source => $winssh32_url,
  #   destination => $winssh32_path,
  #   file_cache_dir => $cache_dir,
  # }

  # download { "winssh-64":
  #   source => $winssh64_url,
  #   destination => $winssh64_path,
  #   file_cache_dir => $cache_dir,
  # }

  # exec { "unzip-winssh-32":
  #   command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${winssh32_path} -y",
  #   creates => "$cache_dir\\OpenSSH-Win32",
  #   cwd => $cache_dir,
  #   require => [
  #     Download["winssh-32"],
  #   ],
  # }

  # exec { "unzip-winssh-64":
  #   command => "\"C:\\Program Files\\7-Zip\\7z.exe\" x ${winssh64_path} -y",
  #   creates => "$cache_dir\\OpenSSH-Win64",
  #   cwd => $cache_dir,
  #   require => [
  #     Download["winssh-64"],
  #   ],
  # }

  # exec { "install-winssh-32":
  #   command => "cmd /c \"move ${cache_dir}\\OpenSSH-Win32\\* ${embedded_dir_32}\\bin",
  #   creates => "${embedded_dir_32}\\bin\\ssh.exe",
  #   require => [
  #     Exec["unzip-winssh-32"],
  #   ],
  # }

  # exec { "install-winssh-64":
  #   command => "cmd /c \"move ${cache_dir}\\OpenSSH-Win64\\* ${embedded_dir_64}\\bin",
  #   creates => "${embedded_dir_64}\\bin\\ssh.exe",
  #   require => [
  #     Exec["unzip-winssh-64"],
  #   ],
  # }

  # NOTE: Once this is enabled the installer needs to be converted to
  # an EXE to chain install the required msi for providing vcruntime140.dll
  # curl::windows{ "x64":
  #   install_dir => $embedded_dir_64,
  #   file_cache_dir => $cache_dir,
  #   target_arch => "x64",
  # }

  # curl::windows{ "x86":
  #   install_dir => $embedded_dir_32,
  #   file_cache_dir => $cache_dir,
  #   target_arch => "x86",
  # }

  class { "rubyencoder::loaders":
    path => $staging_dir,
    require => [
      Powershell["build-substrate"],
    ],
  }

  # The vctip.exe / mspdbsrv.exe processes may be hanging around from msbuild
  # setups. Ensure all of them are dead so we don't get stuck with an open
  # connection that's waiting for the process to complete

  # exec { "kill-vctip":
  #   command => "cmd /c \"taskkill /F /IM vctip.exe /T",
  #   require => [
  #     Curl::Windows["x86"],
  #     Curl::Windows["x64"],
  #   ],
  # }

  # exec { "kill-mspdbsrv":
  #   command => "cmd /c \"taskkill /F /IM mspdbsrv.exe /T",
  #   require => [
  #     Curl::Windows["x86"],
  #     Curl::Windows["x64"],
  #   ],
  # }

}
