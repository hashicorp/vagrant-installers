# == Class: vagrant_installer::staging
#
# This makes the staging directory for Vagrant.
#
class vagrant_installer::staging {
  $dist_dir        = $vagrant_installer::params::dist_dir
  $file_sep        = $vagrant_installer::params::file_sep
  $staging_dir     = $vagrant_installer::params::staging_dir
  $vagrant_version = $vagrant_installer::params::vagrant_version

  $archive_name_raw = "vagrant_${vagrant_version}_${kernel}_${hardwaremodel}"
  $archive_name = inline_template("<%= @archive_name_raw.downcase %>")
  $archive_path = "${dist_dir}${file_sep}${archive_name}.zip"

  case $kernel {
    'Darwin', 'Linux', 'FreeBSD': { include vagrant_installer::staging::posix }
    'windows': { include vagrant_installer::staging::windows }
    default:   { fail("Unknown operating system to stage.") }
  }

  case $kernel {
    'Darwin', 'Linux', 'FreeBSD': {
      include zip

      $archive_staging_dir = "${staging_dir}/${archive_name}"

      exec { "archive-staging-dir":
        command => "rm -rf ${archive_staging_dir} && mkdir ${archive_staging_dir}",
        require  => Class["vagrant_installer::staging::posix"],
      }

      exec { "copy-archive-contents":
        command => "cp -R ${staging_dir}/bin ${archive_staging_dir} && \
          cp -R ${staging_dir}/embedded ${archive_staging_dir}",
        require => Exec["archive-staging-dir"],
      }

      exec { "archive-installer":
        command => "zip -r ${archive_path} ${archive_name}/",
        creates => $archive_path,
        cwd     => $staging_dir,
        path    => ['/usr/bin', '/usr/local/bin'],
        require => [
          Class["zip"],
          Exec["copy-archive-contents"],
        ],
      }

      exec { "rm-archive-staging-dir":
        command => "rm -rf ${archive_staging_dir}",
        require => Exec["archive-installer"],
      }
    }

    'windows': {
      powershell { "archive-installer":
        content  => template("vagrant_installer/staging/powershell_zip.erb"),
        creates  => $archive_path,
        require  => Class["vagrant_installer::staging::windows"],
      }
    }

    default: { fail("Unknown operating system to archive.") }
  }
}
