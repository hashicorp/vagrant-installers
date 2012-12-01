# == Class: vagrant
#
# This downloads Vagrant source, compiles it, and then installs it.
#
class vagrant(
  $autotools_environment,
  $embedded_dir,
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $revision,
) {
  $source_url = "https://github.com/mitchellh/vagrant/archive/${revision}.tar.gz"
  $source_file_path = "${file_cache_dir}/vagrant-${revision}.tar.gz"
  $source_dir_path = "${file_cache_dir}/vagrant-${revision}"
  $vagrant_gem_path = "${source_dir_path}/vagrant.gem"

  $gem_renamer = "${file_cache_dir}/vagrant_gem_rename.rb"

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
    before      => Exec["untar-vagrant"],
  }

  #------------------------------------------------------------------
  # Download and Compile Vagrant
  #------------------------------------------------------------------
  wget::fetch { "vagrant":
    source      => $source_url,
    destination => $source_file_path,
  }

  exec { "untar-vagrant":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["vagrant"],
  }

  exec { "vagrant-gem-build":
    command     => "gem build vagrant.gemspec",
    cwd         => $source_dir_path,
    refreshonly => true,
    subscribe   => Exec["untar-vagrant"],
  }

  file { $gem_renamer:
    content => template("vagrant/gem_renamer.erb"),
    mode    => "0755",
  }

  exec { "vagrant-gem-rename":
    command => "ruby ${gem_renamer} ${source_dir_path}",
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
    command     => "${embedded_dir}/bin/gem install ${vagrant_gem_path} --no-ri --no-rdoc",
    creates     => "${embedded_dir}/gems/bin/vagrant",
    environment => autotools_flatten_environment($merged_environment),
    logoutput   => true,
    require     => Exec["vagrant-gem-rename"],
  }
}
