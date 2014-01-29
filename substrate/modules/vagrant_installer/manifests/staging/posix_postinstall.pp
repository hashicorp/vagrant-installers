class vagrant_installer::staging::posix_postinstall {
  include vagrant_installer::params

  $embedded_dir = $vagrant_installer::params::embedded_dir

  # We have to remove all the '.la' files because they cause issues
  # with libtool later because they have hardcoded temp paths in them.
  exec { "remove-la-files":
    command => "rm -rf ${embedded_dir}/lib/*.la",
  }
}
