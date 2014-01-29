class vagrant_substrate(
  $build_dir,
  $installer_version,
) {
  $file_sep = $operatingsystem ? {
    'windows' => "\\",
    default   => '/',
  }

  $cache_dir    = "${build_dir}${file_sep}cache"
  $staging_dir  = "${build_dir}${file_sep}staging"
  $embedded_dir = "${staging_dir}${file_sep}embedded"
  $output_dir   = $param_output_dir

  #--------------------------------------------------------------------
  # Stages
  #--------------------------------------------------------------------
  stage { "prepare": }
  stage { "post-staging": }
  stage { "package": }

  Stage["prepare"] ->
  Stage["main"] ->
  Stage["post-staging"] ->
  Stage["package"]

  class { "vagrant_substrate::prepare":
    stage => "prepare",
  }

  class { "vagrant_substrate::staging": }

  class { "vagrant_substrate::post_staging":
    stage => "post-staging",
  }

  class { "vagrant_substrate::package":
    stage => "package",
  }
}
