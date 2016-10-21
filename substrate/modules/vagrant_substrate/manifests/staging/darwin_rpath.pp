# == Define: vagrant_substrate::staging::darwin_rpath
#
# A helper to set proper rpath information on darwin
#
define vagrant_substrate::staging::darwin_rpath(
  $add_rpath=[
    "@loader_path/../lib",
    "@executable_path/../lib"
  ],
  $change_install_names={},
  $new_lib_path,
  $remove_rpath,
  $target_file_path=$name,
) {

  # Always set the header ID. If it is not applicable to the target file
  # given, it will simply be a no-op
  exec { "set-${name}-id":
    command => "install_name_tool -id ${new_lib_path} ${target_file_path}",
  }

  create_resources(
    vagrant_substrate::staging::darwin_name_change,
    $change_install_names,
    { target_file_path => $target_file_path }
  )

  $add_rpath_stringify = join($add_rpath, "<${target_file_path}>,")
  $hacky_add_rpath = split("${add_rpath_stringify}<${target_file_path}>", ",")
  vagrant_substrate::staging::darwin_add_rpath { $hacky_add_rpath:
    target_file_path => $target_file_path,
  }

  exec { "remove-${name}-rpath":
    command => "install_name_tool -delete_rpath ${remove_rpath} ${target_file_path}",
    onlyif => "otool -l ${target_file_path} | grep 'path ${remove_rpath}'"
  }
}

define vagrant_substrate::staging::darwin_name_change(
  $original,
  $replacement,
  $target_file_path,
) {
  exec { "change-${name}-${original}":
    command => "install_name_tool -change ${original} ${replacement} ${target_file_path}",
  }
}

define vagrant_substrate::staging::darwin_add_rpath(
  $new_rpath=$name,
  $target_file_path
) {
  $clean_rpath = regsubst($new_rpath, regexpescape("<${target_file_path}>"), "")
  exec { "new-rpath-${name}-${target_file_path}":
    command => "install_name_tool -add_rpath ${clean_rpath} ${target_file_path}",
    unless => "otool -l ${target_file_path} | grep 'path ${clean_rpath}'"
  }
}
