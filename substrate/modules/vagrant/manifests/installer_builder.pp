# == Class: vagrant::installer_builder
#
# This installs the necessary files to build installers for Vagrant
# on this machine. This does not build an actual installer.
#
# === Parameters
#
# [*install_dir*]
#     This is the directory where installer builders will be installed
#     to.
#
class vagrant::installer_builder(
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $install_dir = params_lookup('install_dir'),
  $local_hiera = undef,
  $revision,
) {
  require git
  require rsync

  if !$file_cache_dir {
    fail("You must set a file_cache_dir.")
  }

  if !$install_dir {
    fail("You must set an install_dir.")
  }

  $source_url = "https://github.com/mitchellh/vagrant-installers/archive/${revision}.tar.gz"
  $source_dir_path = "${file_cache_dir}/vagrant-installers-${revision}"
  $source_package_path = "${file_cache_dir}/vagrant-installers-${revision}.tar.gz"

  util::recursive_directory { $install_dir: }

  download { "vagrant-installer-builder":
    source      => $source_url,
    destination => $source_package_path,
  }

  exec { "untar-vagrant-installer-builder":
    command => "tar xvzf ${source_package_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Download["vagrant-installer-builder"],
    notify  => Exec["rsync-vagrant-installer-builder"],
  }

  package { "librarian-puppet":
    provider => gem,
  }

  exec { "vagrant-installer-modules":
    command     => "librarian-puppet install",
    creates     => "${source_dir_path}/modules",
    cwd         => $source_dir_path,
    environment => "HOME=${source_dir_path}",
    timeout     => 0,
    require     => [
      Package["librarian-puppet"],
      Exec["untar-vagrant-installer-builder"],
    ],
  }

  if $local_hiera {
    file { "${source_dir_path}/hiera/local.yaml":
      content => $local_hiera,
      mode    => "0644",
      require => Exec["untar-vagrant-installer-builder"],
      notify  => Exec["rsync-vagrant-installer-builder"],
    }
  }

  exec { "rsync-vagrant-installer-builder":
    command     => "rsync --archive --delete ${source_dir_path}/ ${install_dir}/",
    refreshonly => true,
    timeout     => 0,
    require     => Exec["vagrant-installer-modules"],
  }
}
