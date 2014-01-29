# == Class: vagrant_installer::package::arch
#
# This creates a package for Vagrant for Arch.
#
class vagrant_installer::package::arch {
  require vagrant_installer::package::linux

  $file_cache_dir = hiera("file_cache_dir")
  $dist_dir      = $vagrant_installer::params::dist_dir
  $staging_dir    = $vagrant_installer::params::staging_dir
  $vagrant_version = $vagrant_installer::params::vagrant_version

  $pkgname = "vagrant"
  $pkgver  = $vagrant_version
  $setup_dir = "${file_cache_dir}/arch_setup"
  $source_package = "vagrant.tar.gz"

  $final_output_path = "${dist_dir}/vagrant_${vagrant_version}_${hardwaremodel}.pkg.tar.xz"
  $script_renamer = "${file_cache_dir}/arch_renamer"

  #------------------------------------------------------------------
  # Setup the working directory we'll use
  #------------------------------------------------------------------
  exec { "clear-arch-setup-dir":
    command => "rm -rf ${setup_dir}",
  }

  util::recursive_directory { $setup_dir:
    require => Exec["clear-arch-setup-dir"],
  }

  file { $setup_dir:
    ensure  => directory,
    owner   => "root",
    group   => "root",
    mode    => "0755",
    require => Util::Recursive_directory[$setup_dir],
  }

  #------------------------------------------------------------------
  # Package
  #------------------------------------------------------------------
  # Tar up the staging directory
  exec { "tar-staging-dir":
    command => "tar cvzf '${source_package}' ${staging_dir}",
    creates => "${setup_dir}/${source_package}",
    cwd     => $setup_dir,
    require => File[$setup_dir],
  }

  # Create the PKGBUILD file so we can create a binary package
  file { "${setup_dir}/PKGBUILD":
    content => template("vagrant_installer/package/arch_pkgbuild.erb"),
    owner   => "root",
    group   => "root",
    mode    => "0644",
    require => File[$setup_dir],
  }

  # Create the binary package
  exec { "makepkg":
    command => "makepkg --asroot",
    cwd     => $setup_dir,
    require => [
      Exec["tar-staging-dir"],
      File["${setup_dir}/PKGBUILD"],
    ],
  }

  # Rename it over to our final path
  util::script { $script_renamer:
    content => template("vagrant_installer/package/arch_renamer.erb"),
  }

  # Rename it
  exec { "rename-arch-pkg":
    command => "${script_renamer} ${setup_dir} ${final_output_path}",
    creates => $final_output_path,
    require => [
      Exec["makepkg"],
      Util::Script[$script_renamer],
    ],
  }
}
