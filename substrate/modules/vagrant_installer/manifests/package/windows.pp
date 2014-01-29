# == Class: vagrant_installer::package::windows
#
# This creates a package for Vagrant for Windows.
#
class vagrant_installer::package::windows {
  $file_cache_dir  = hiera("file_cache_dir")
  $upgrade_code    = "1a672674-6722-4e3a-9061-8f539a8b0ed6"
  $dist_dir        = $vagrant_installer::params::dist_dir
  $staging_dir     = $vagrant_installer::params::staging_dir
  $vagrant_version = $vagrant_installer::params::vagrant_version
  $wix_dir         = "${file_cache_dir}\\wix-binaries"

  $final_output_path = "${dist_dir}/Vagrant_${vagrant_version}.msi"

  $files_component_group = "VagrantDir"
  $pkg_staging_dir = "${file_cache_dir}\\pkg-staging"
  $pkg_assets_dir  = "${pkg_staging_dir}\\assets"

  #------------------------------------------------------------------
  # Directories
  #------------------------------------------------------------------
  exec { "clear-pkg-staging-dir":
    command => "cmd.exe /C rmdir.exe /S /Q ${pkg_staging_dir} & exit /B 0",
  }

  util::recursive_directory { $pkg_staging_dir:
    require => Exec["clear-pkg-staging-dir"],
  }

  #------------------------------------------------------------------
  # WiX
  #------------------------------------------------------------------
  util::recursive_directory { $wix_dir: }

  class { "wix":
    install_path => $wix_dir,
    require      => Util::Recursive_directory[$wix_dir],
  }

  #------------------------------------------------------------------
  # Resources
  #------------------------------------------------------------------
  file { $pkg_assets_dir:
    ensure  => directory,
    require => Util::Recursive_directory[$pkg_staging_dir],
  }

  file { "${pkg_assets_dir}/bg_banner.bmp":
    source  => "puppet:///modules/vagrant_installer/windows/bg_banner.bmp",
    tag     => "pkg-resource",
    require => File[$pkg_assets_dir],
  }

  file { "${pkg_assets_dir}/bg_dialog.bmp":
    source  => "puppet:///modules/vagrant_installer/windows/bg_dialog.bmp",
    tag     => "pkg-resource",
    require => File[$pkg_assets_dir],
  }

  file { "${pkg_assets_dir}/license.rtf":
    source  => "puppet:///modules/vagrant_installer/windows/license.rtf",
    tag     => "pkg-resource",
    require => File[$pkg_assets_dir],
  }

  #------------------------------------------------------------------
  # WiX Files
  #------------------------------------------------------------------
  $wxi_path = "${pkg_staging_dir}\\vagrant-config.wxi"
  $wxl_path = "${pkg_staging_dir}\\vagrant-en-us.wxl"
  $wxs_path = "${pkg_staging_dir}\\vagrant-main.wxs"

  file { $wxi_path:
    content => template("vagrant_installer/package/windows_config.wxi.erb"),
    require => Util::Recursive_directory[$pkg_staging_dir],
  }

  file { $wxl_path:
    content => template("vagrant_installer/package/windows_en-us.wxl.erb"),
    require => Util::Recursive_directory[$pkg_staging_dir],
  }

  file { $wxs_path:
    content => template("vagrant_installer/package/windows_main.wxs.erb"),
    require => Util::Recursive_directory[$pkg_staging_dir],
  }

  #------------------------------------------------------------------
  # WiX Execute!
  #------------------------------------------------------------------
  $wixobj_files_path = "${pkg_staging_dir}\\vagrant-files.wixobj"
  $wixobj_main_path = "${pkg_staging_dir}\\vagrant-main.wixobj"
  $wxs_files_path = "${pkg_staging_dir}\\vagrant-files.wxs"

  $candle_flags = "-nologo -I${pkg_staging_dir} -dVagrantSourceDir=\"${staging_dir}\" -out ${pkg_staging_dir}\\"
  $harvest_flags = "-nologo -srd -gg -cg ${files_component_group} -dr VAGRANTAPPDIR -var var.VagrantSourceDir -out ${wxs_files_path}"
  $light_flags = "-nologo -ext WixUIExtension -cultures:en-us -loc ${wxl_path} -out ${final_output_path}"

  exec { "harvest-vagrant":
    command => "${wix_dir}\\heat.exe dir \"${staging_dir}\" ${harvest_flags}",
    creates => $wxs_files_path,
    timeout => 0,
    require => [
      Class["wix"],
      Util::Recursive_directory[$pkg_staging_dir],
    ],
  }

  exec { "compile-vagrant":
    command => "${wix_dir}\\candle.exe ${candle_flags} ${wxs_files_path} ${wxs_path}",
    creates => $wixobj_files_path,
    timeout => 0,
    require => [
      Class["wix"],
      Exec["harvest-vagrant"],
    ],
  }

  exec { "link-vagrant":
    command => "${wix_dir}\\light.exe ${light_flags} ${wixobj_files_path} ${wixobj_main_path}",
    creates => $final_output_path,
    returns => [0, 204],
    timeout => 0,
    require => [
      Class["wix"],
      Exec["compile-vagrant"],
    ],
  }
}
