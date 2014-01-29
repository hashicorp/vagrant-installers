# == Class: vagrant_installer::prepare
#
# This prepares everything for creating installers. This is run in a run
# stage prior to the main stage, so you must be VERY CAREFUL about
# resource ordering here.
#
class vagrant_installer::prepare {
  include vagrant_installer::params

  $file_cache_dir = $vagrant_installer::params::file_cache_dir
  $staging_dir    = $vagrant_installer::params::staging_dir
  $embedded_dir   = $vagrant_installer::params::embedded_dir
  $dist_dir       = $vagrant_installer::params::dist_dir

  # Sometimes when we're debugging, its nice to keep these directories
  # around to keep the Puppet runs fast. This will make that happen.
  if !$param_keep_dirs {
    case $operatingsystem {
      'windows': {
        # 'rmdir' is SO incredibly faster than the Puppet file resource
        # on Windows, so we shell out to that.
        exec { "clear-dist-dir":
          command => "cmd.exe /C rmdir.exe /S /Q ${dist_dir} & exit /B 0",
          tag     => "prepare-clear",
        }

        exec { "clear-staging-dir":
          command => "cmd.exe /C rmdir.exe /S /Q ${staging_dir} & exit /B 0",
          tag     => "prepare-clear",
        }
      }

      default: {
        # 'rm' is again much faster than the Puppet file resource, so we
        # just execute that directly.
        exec { "clear-dist-dir":
          command => "rm -rf ${dist_dir}",
          tag     => "prepare-clear",
        }

        exec { "clear-staging-dir":
          command => "rm -rf ${staging_dir}",
          tag     => "prepare-clear",
        }
      }
    }

    # Run these prior to any of the directories, so that we
    # delete them prior to making them.
    Exec <| tag == "prepare-clear" |> -> Util::Recursive_directory <| tag == "prepare" |>
  }

  util::recursive_directory { [
    $file_cache_dir,
    $staging_dir,
    "${staging_dir}/bin",
    $embedded_dir,
    "${embedded_dir}/bin",
    "${embedded_dir}/etc",
    "${embedded_dir}/include",
    "${embedded_dir}/lib",
    "${embedded_dir}/share",
    $dist_dir,]:
    tag => "prepare",
  }
}
