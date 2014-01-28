class vagrant_substrate::post_staging {
  case $kernel {
    'Darwin', 'Linux': {
      require vagrant_substrate::post_staging::posix
    }
  }
}
