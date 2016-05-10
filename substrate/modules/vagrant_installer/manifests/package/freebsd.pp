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

  $final_output_path = "${dist_dir}/vagrant-${vagrant_version}.txz"

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

  # Append list of package's directories to +MANIFEST
  $dirs_list_cmd = "find * -type d | sed -e 's/^/  - \\//'"
  $dirs_cmd = "echo \"dirs:\" >> ${setup_dir}/+MANIFEST;  $dirs_list_cmd >> ${setup_dir}/+MANIFEST"
  exec { "append-dirs-to-manifest":
    command => $dirs_cmd,
    cwd     => $staging_dir,
    require => File["${setup_dir}/+MANIFEST"],
  }

  # Append list of package's files to +MANIFEST
  $files_list_cmd = "for F in `find * -type f`; do echo \"  `echo \$F | sed -e 's/^/\\//'`: `sha256 -q \$F`\"; done"
  $files_cmd = "echo \"files:\" >> ${setup_dir}/+MANIFEST;  $files_list_cmd >> ${setup_dir}/+MANIFEST"
  exec { "append-files-to-manifest":
    command => $files_cmd,
    cwd     => $staging_dir,
    require => [ File["${setup_dir}/+MANIFEST"], Exec['append-dirs-to-manifest'] ],
  }

  # Append list of package's symlinks to +MANIFEST
  #$symlink_list_cmd = "for F in `find * -type l`; do echo \"  `echo \$F | sed -e 's/^/\\//'`: `sha256 -q \$F`\"; done"
  #$symlink_cmd = "echo \"files:\" >> ${setup_dir}/+MANIFEST;  $files_list_cmd >> ${setup_dir}/+MANIFEST"
  $symlink_cmd = "for F in `find * -type l`; do echo \"  `echo \$F | sed -e 's/^/\\//'`: '-'\"; done >> ${setup_dir}/+MANIFEST"
  exec { "append-symlinks-to-manifest":
    command => $symlink_cmd,
    cwd     => $staging_dir,
    require => [ File["${setup_dir}/+MANIFEST"], Exec['append-files-to-manifest'] ],
    provider => 'shell',
  }

  # Create the binary package
  exec { "pkg-create":
    command => "pkg create -o $dist_dir -r $staging_dir -m $setup_dir",
    cwd     => $staging_dir,
    require => [
      File["${setup_dir}/+MANIFEST"],
      Exec['append-dirs-to-manifest'],
      Exec['append-files-to-manifest'],
      Exec['append-symlinks-to-manifest'],
    ],
  }
}
