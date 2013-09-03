# == Class: vagrant_installer::package::linux_stage
#
# This modifies the staging directory a bit more for a linux package,
# specifically by making a "/usr/bin/vagrant" and setting up some other
# paths within the package.
#
class vagrant_installer::package::linux {
  $linux_prefix       = hiera("linux_prefix")
  $file_cache_dir     = $vagrant_installer::params::file_cache_dir
  $script_stage_linux = "${file_cache_dir}/linux_stage"
  $staging_dir        = $vagrant_installer::params::staging_dir

  util::script { $script_stage_linux:
    content => template("vagrant_installer/package/linux_stage.sh.erb"),
  }

  exec { $script_stage_linux:
    cwd     => $staging_dir,
    unless  => "test -d opt",
    require => Util::Script[$script_stage_linux],
  }

  util::script { "${staging_dir}/usr/bin/vagrant":
    content => template("vagrant_installer/vagrant_linux_proxy.erb"),
    require => Exec[$script_stage_linux],
  }
}
