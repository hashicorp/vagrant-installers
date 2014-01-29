# == Class: vagrant_installer::params
#
# This is just a variable farm for the vagrant_installer set of classes.
#
class vagrant_installer::params {
  $file_cache_dir       = hiera("file_cache_dir")
  $installer_version    = hiera("installer_version")

  $file_sep = $operatingsystem ? {
    'windows' => "\\",
    default   => '/',
  }

  $dist_dir = $param_dist_dir ? {
    undef   => "${file_cache_dir}${file_sep}dist",
    default => $param_dist_dir
  }

  $staging_dir      = hiera("installer_staging_dir")
  $embedded_dir     = "${staging_dir}${file_sep}embedded"
  $vagrant_revision = $param_vagrant_revision
  $vagrant_version  = $param_vagrant_version

  if !$vagrant_revision {
    fail("A vagrant revision must be specified.")
  }

  if !$vagrant_version {
    fail("A vagrant version must be specified.")
  }
}
