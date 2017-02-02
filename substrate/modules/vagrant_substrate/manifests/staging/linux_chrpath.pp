# == Define: vagrant_substrate::staging::linux_chrpath
#
# A helper to set proper RUN_PATH information on Linux
#
define vagrant_substrate::staging::linux_chrpath(
  $new_rpath='$ORIGIN/../lib:/opt/vagrant/embedded/lib',
  $target_file_path=$name,
) {

  exec { "set-${name}-rpath":
    command => "chrpath --replace '${new_rpath}' '${target_file_path}'",
    onlyif => "chrpath --list '${target_file_path}' | grep RPATH",
  }

  exec { "convert-${name}-runpath":
    command => "chrpath --convert '${target_file_path}'",
    onlyif => "chrpath '${target_file_path}' | grep RPATH",
    subscribe => Exec["set-${name}-rpath"],
  }

}