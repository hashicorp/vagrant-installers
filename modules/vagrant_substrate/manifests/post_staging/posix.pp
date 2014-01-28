class vagrant_substrate::post_staging::posix {
  include vagrant_substrate

  $embedded_dir = $vagrant_substrate::embedded_dir

  # We have to remove all the '.la' files because they cause issues
  # with libtool later because they have hardcoded temp paths in them.
  exec { "remove-la-files":
    command => "rm -rf ${embedded_dir}/lib/*.la",
  }
}
