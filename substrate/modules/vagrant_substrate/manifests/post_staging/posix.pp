class vagrant_substrate::post_staging::posix {
  include vagrant_substrate

  $cache_dir = $vagrant_substrate::cache_dir
  $embedded_dir = $vagrant_substrate::embedded_dir
  $installation_dir = hiera("installation_dir")
  $relpath_sh = "${cache_dir}/relpath.sh"
  if $operatingsystem == 'Darwin' {
    $relpath_content = "puppet:///modules/vagrant_substrate/darwin_rpath.sh"
  } else {
    $relpath_content = "puppet:///modules/vagrant_substrate/linux_rpath.sh"
  }

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
    command => "find ${embedded_dir}/ -name '*.la' -exec rm {} \\;",
  }

  file { $relpath_sh:
    source => $relpath_content,
    mode => "0755",
  }

  exec { "rpath-update":
    command => "${relpath_sh} ${embedded_dir}",
    require => [
      File[$relpath_sh],
    ],
  }

  $destination_dir = "${installation_dir}/embedded"

  if $operatingsystem == 'Darwin' {
    $sed_i = "-i ''"
  } else {
    $sed_i = "-i"
  }

  exec { "scrub-substrate-paths":
    command => "grep --binary-files=without-match -R '${embedded_dir}' '${embedded_dir}' | cut -d: -f1 | xargs sed ${sed_i} 's@${embedded_dir}@${destination_dir}@g'",
  }
}
