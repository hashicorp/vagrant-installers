class vagrant_substrate::prepare {
  include vagrant_substrate

  $cache_dir    = $vagrant_substrate::cache_dir
  $embedded_dir = $vagrant_substrate::embedded_dir
  $staging_dir  = $vagrant_substrate::staging_dir
  $output_dir   = $vagrant_substrate::output_dir

  #--------------------------------------------------------------------
  # Clean the directories
  #--------------------------------------------------------------------
  case $operatingsystem {
    'windows': {
      # 'rmdir' is SO incredibly faster than the Puppet file resource
      # on Windows, so we shell out to that.
      exec { "clear-staging-dir":
        command => "cmd.exe /C rmdir.exe /S /Q ${staging_dir} & exit /B 0",
        tag     => "prepare-clear",
      }
    }

    default: {
      # 'rm' is again much faster than the Puppet file resource, so we
      # just execute that directly.
      exec { "clear-staging-dir":
        command => "rm -rf ${staging_dir}",
        tag     => "prepare-clear",
      }
    }
  }

  #--------------------------------------------------------------------
  # Prepare the directories
  #--------------------------------------------------------------------
  # Run deletes prior to creating directories
  Exec <| tag == "prepare-clear" |> -> Util::Recursive_directory <| tag == "prepare" |>

  util::recursive_directory { [
    $cache_dir,
    $staging_dir,
    "${staging_dir}/bin",
    $embedded_dir,
    "${embedded_dir}/bin",
    "${embedded_dir}/etc",
    "${embedded_dir}/include",
    "${embedded_dir}/lib",
    "${embedded_dir}/share",
    $output_dir,]:
      tag => "prepare",
  }
}
