# == Class: vagrant_installer::prepare
#
# This prepares everything for creating installers. This is run in a run
# stage prior to the main stage, so you must be VERY CAREFUL about
# resource ordering here.
#
class vagrant_installer::prepare {
  $staging_dir  = $vagrant_installer::params::staging_dir
  $embedded_dir = $vagrant_installer::params::embedded_dir

  util::recursive_directory { [
    $staging_dir,
    $embedded_dir,
    "${embedded_dir}/bin",
    "${embedded_dir}/include",
    "${embedded_dir}/lib",
    "${embedded_dir}/share",]: }
}
