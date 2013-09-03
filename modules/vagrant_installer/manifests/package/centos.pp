# == Class: vagrant_installer::package::centos
#
# This creates a package for Vagrant for CentOS.
#
class vagrant_installer::package::centos {
  require fpm
  require vagrant_installer::package::linux

  $dist_dir        = $vagrant_installer::params::dist_dir
  $staging_dir     = $vagrant_installer::params::staging_dir
  $vagrant_version = $vagrant_installer::params::vagrant_version

  $final_output_path = "${dist_dir}/vagrant_${vagrant_version}_${hardwaremodel}.rpm"

  $fpm_args = "-p '${final_output_path}' -n vagrant -v '${vagrant_version}' -s dir -t rpm --prefix '/' -C '${staging_dir}'"

  package { "rpm-build":
    ensure => installed,
  }

  exec { "fpm-vagrant-rpm":
    command => "fpm ${fpm_args} .",
    cwd     => $staging_dir,
    creates => $final_output_path,
    require => Package["rpm-build"],
  }
}
