# == Class: vagrant_installer::params
#
# This is just a variable farm for the vagrant_installer set of classes.
#
class vagrant_installer::params {
  $staging_dir  = hiera("installer_staging_dir")
  $embedded_dir = "${staging_dir}/embedded"
}
