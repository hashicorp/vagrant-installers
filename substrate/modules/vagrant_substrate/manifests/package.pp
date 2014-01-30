class vagrant_substrate::package {
  include vagrant_substrate

  $cache_dir    = $vagrant_substrate::cache_dir
  $file_sep     = $vagrant_substrate::file_sep
  $output_dir   = $vagrant_substrate::output_dir
  $staging_dir  = $vagrant_substrate::staging_dir

  $package_name_raw = "substrate_${operatingsystem}_${hardwaremodel}.zip"
  $package_name     = inline_template("<%= @package_name_raw.downcase %>")
  $package_path     = "${output_dir}${file_sep}${package_name}"

  case $kernel {
    'Darwin', 'Linux': {
      include zip

      $archive_dir = "${cache_dir}/archive"
      $archive_substrate_dir = "${archive_dir}/substrate"

      exec { "package-staging-dir":
        command => "rm -rf ${archive_dir} && mkdir -p ${archive_substrate_dir}",
      }

      exec { "copy-staging-dir":
        command => "cp -R ${staging_dir}/* ${archive_substrate_dir}",
        require => Exec["package-staging-dir"],
      }

      exec { "package-substrate":
        command => "zip -r ${package_path} substrate/",
        creates => $package_path,
        cwd     => $archive_dir,
        require => [
          Class["zip"],
          Exec["copy-staging-dir"],
        ],
      }
    }

    'windows': {
      powershell { "package-substrate":
        content        => template("vagrant_substrate/package_windows.ps1.erb"),
        creates        => $package_path,
        file_cache_dir => $cache_dir,
      }
    }
  }
}
