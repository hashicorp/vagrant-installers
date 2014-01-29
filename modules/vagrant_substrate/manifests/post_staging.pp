class vagrant_substrate::post_staging {
  include vagrant_substrate

  $build_dir   = $vagrant_substrate::build_dir
  $file_sep    = $vagrant_substrate::file_sep
  $scripts_dir = "${build_dir}${file_sep}scripts"

  #-------------------------------------------------------------
  # Platform-specific changes
  #-------------------------------------------------------------
  case $kernel {
    'Darwin', 'Linux': {
      require vagrant_substrate::post_staging::posix
    }
  }

  #-------------------------------------------------------------
  # Scripts
  #-------------------------------------------------------------
  util::recursive_directory { $scripts_dir: }

  # Install Vagrant script
  $script_vagrant_install = "${scripts_dir}${file_sep}install_vagrant.sh"
  file { $script_vagrant_install:
    content => template("vagrant_substrate/post_staging/install_vagrant.sh.erb"),
    mode    => "0755",
    require => Util::Recursive_directory[$scripts_dir],
  }
}
