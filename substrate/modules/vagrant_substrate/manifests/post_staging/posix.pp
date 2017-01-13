class vagrant_substrate::post_staging::posix {
  include vagrant_substrate

  $embedded_dir = $vagrant_substrate::embedded_dir
  $installation_dir = hiera("installation_dir")

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

  $new_rpath = "\$ORIGIN/../lib:${installation_dir}/embedded/lib"
  exec { "replace-so-rpaths":
    command => "find ${embedded_dir}/{lib64,lib/*}/ -name '*.so' -exec chrpath --replace '${new_rpath}' {} \\;",
    onlyif => "ls ${embedded_dir}/lib64",
  }

  exec { "replace-so-rpaths-constrained":
    command => "find ${embedded_dir}/lib/*/ -name '*.so' -exec chrpath --replace '${new_rpath}' {} \\;",
    unless => "ls ${embedded_dir}/lib64",
  }

  exec { "convert-so-runpaths":
    command => "find ${embedded_dir}/{lib64,lib/*}/ -name '*.so' -exec chrpath --convert {} \\;",
    subscribe => Exec["replace-so-rpaths"],
    refreshonly => true,
  }

  exec { "convert-so-runpaths-constrained":
    command => "find ${embedded_dir}/lib/*/ -name '*.so' -exec chrpath --convert {} \\;",
    subscribe => Exec["replace-so-rpaths-constrained"],
    refreshonly => true
  }

  $destination_dir = "${installation_dir}/embedded"
  exec { "scrub-substrate-paths":
    command => "grep -l -I -R '${embedded_dir}' '${embedded_dir}' | xargs sed -i 's@${embedded_dir}@${destination_dir}@g'",
    onlyif => "grep -l -I -R '${embedded_dir}' '${embedded_dir}'",
  }
}
