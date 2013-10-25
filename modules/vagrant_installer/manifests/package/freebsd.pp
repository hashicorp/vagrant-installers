# == Class: vagrant_installer::package::freebsd
#
# This creates a package for Vagrant for FreeBSD.
#
class vagrant_installer::package::freebsd {
  # This feels dirty.
  require vagrant_installer::package::linux

  $file_cache_dir = hiera("file_cache_dir")
  $dist_dir      = $vagrant_installer::params::dist_dir
  $staging_dir    = $vagrant_installer::params::staging_dir
  $vagrant_version = $vagrant_installer::params::vagrant_version

  $pkgname = "vagrant"
  $pkgver  = $vagrant_version
  $setup_dir = "${file_cache_dir}/freebsd_setup"
  $source_package = "vagrant.tar.gz"

  $final_output_path = "${dist_dir}/vagrant_${vagrant_version}_${hardwaremodel}.txz"

  #------------------------------------------------------------------
  # Setup the working directory we'll use
  #------------------------------------------------------------------
  exec { "clear-freebsd-setup-dir":
    command => "rm -rf ${setup_dir}",
  }

  util::recursive_directory { $setup_dir:
    require => Exec["clear-freebsd-setup-dir"],
  }

  file { $setup_dir:
    ensure  => directory,
    owner   => "root",
    group   => "wheel",
    mode    => "0755",
    require => Util::Recursive_directory[$setup_dir],
  }

  #------------------------------------------------------------------
  # Package
  #------------------------------------------------------------------

  # Create the +MANIFEST file so we can create a binary package
  file { "${setup_dir}/+MANIFEST":
    content => template("vagrant_installer/package/freebsd_pkgbuild.erb"),
    owner   => "root",
    group   => "wheel",
    mode    => "0644",
    require => File[$setup_dir],
  }

  # Create the binary package
  exec { "createpkg":
    command => "pkg create -m $setup_dir",
    cwd     => $setup_dir,
    require => File["${setup_dir}/+MANIFEST"],
  }
}
