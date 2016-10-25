class vagrant_substrate::post_staging {
  #-------------------------------------------------------------
  # Platform-specific changes
  #-------------------------------------------------------------
  case $kernel {
    'Darwin', 'Linux', 'FreeBSD': {
      require vagrant_substrate::post_staging::posix
    }
  }
}
