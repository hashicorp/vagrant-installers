class vagrant_substrate::post_staging::posix {
  include vagrant_substrate

  $embedded_dir = $vagrant_substrate::embedded_dir

  exec { "clear-openssl-man":
    command => "rm -rf ${embedded_dir}/ssl/man",
  }

  exec { "clear-share-man":
    command => "rm -rf ${embedded_dir}/share/man",
  }

  exec { "clear-share-doc":
    command => "rm -rf ${embedded_dir}/share/doc",
  }

  exec { "clear-share-gtk-doc":
    command => "rm -rf ${embedded_dir}/share/gtk-doc",
  }

  # We have to remove all the '.la' files because they cause issues
  # with libtool later because they have hardcoded temp paths in them.
  exec { "remove-la-files":
    command => "rm -rf ${embedded_dir}/lib/*.la",
  }
}
