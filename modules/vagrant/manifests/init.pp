# == Class: vagrant
#
# This downloads Vagrant source, compiles it, and then installs it.
#
class vagrant(
  $autotools_environment = {},
  $embedded_dir,
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $revision,
) {
  $extension = $operatingsystem ? {
    'windows' => 'zip',
    default   => 'tar.gz',
  }

  $gem_renamer = path("${file_cache_dir}/vagrant_gem_rename.rb")
  $source_url = "https://github.com/mitchellh/vagrant/archive/v${revision}.${extension}"
  $source_file_path = path("${file_cache_dir}/vagrant-${revision}.${extension}")
  $source_dir_path  = path("${file_cache_dir}/vagrant-${revision}")
  $vagrant_gem_path = path("${source_dir_path}/vagrant.gem")

  if $operatingsystem == 'windows' {
    $extract_command   = "cmd.exe /C exit /B 0"
    $gem_command       = "${embedded_dir}\\bin\\gem.bat"
    $gem_build_command = "cmd.exe /C ${gem_command} build vagrant.gemspec"
    $ruby_command      = "cmd.exe /C ${embedded_dir}\\bin\\ruby.exe"
  } else {
    $extract_command   = "tar xvzf ${source_file_path}"
    $gem_command       = "${embedded_dir}/bin/gem"
    $gem_build_command = "${gem_command} build vagrant.gemspec"
    $ruby_command      = "${embedded_dir}/bin/ruby"
  }

  $extra_environment = {
    "GEM_HOME" => "${embedded_dir}/gems",
    "GEM_PATH" => "${embedded_dir}/gems",
  }

  $merged_environment = autotools_merge_environments(
    $autotools_environment, $extra_environment)

  #------------------------------------------------------------------
  # Resetter
  #------------------------------------------------------------------
  # Users outside this class should notify this resource if they want
  # to force a recompile of Vagrant.
  exec { "reset-vagrant":
    command     => "rm -rf ${source_dir_path}",
    refreshonly => true,
    before      => Exec["extract-vagrant"],
  }

  #------------------------------------------------------------------
  # Download and Compile Vagrant
  #------------------------------------------------------------------
  download { "vagrant":
    source      => $source_url,
    destination => $source_file_path,
  }

  if $operatingsystem == 'windows' {
    # Unzip things on Windows
    powershell { "extract-vagrant":
      content => template("vagrant/windows_extract.erb"),
      creates => $source_dir_path,
      require => Download["vagrant"],
      before  => Exec["extract-vagrant"],
    }
  }

  exec { "extract-vagrant":
    command => $extract_command,
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Download["vagrant"],
  }

  exec { "vagrant-gem-build":
    command => $gem_build_command,
    creates => $vagrant_gem_path,
    cwd     => $source_dir_path,
    require => Exec["extract-vagrant"],
  }

  file { $gem_renamer:
    content => template("vagrant/gem_renamer.erb"),
    mode    => "0755",
  }

  exec { "vagrant-gem-rename":
    command => "${ruby_command} ${gem_renamer} ${source_dir_path}",
    creates => $vagrant_gem_path,
    require => [
      Exec["vagrant-gem-build"],
      File[$gem_renamer],
    ],
  }

  #------------------------------------------------------------------
  # Install the gem into the proper location
  #------------------------------------------------------------------
  exec { "vagrant-gem-install":
    command     => "${gem_command} install ${vagrant_gem_path} --no-ri --no-rdoc",
    creates     => "${embedded_dir}/gems/bin/vagrant",
    environment => autotools_flatten_environment($merged_environment),
    logoutput   => true,
    tries       => 3,
    try_sleep   => 10,
    require     => Exec["vagrant-gem-rename"],
  }
}
