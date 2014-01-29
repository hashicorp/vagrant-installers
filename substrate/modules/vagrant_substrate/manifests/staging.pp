class vagrant_substrate::staging {
  case $kernel {
    'Darwin', 'Linux': { include vagrant_substrate::staging::posix }
    'windows': { include vagrant_staging::staging::windows }
    default:   { fail("Unknown operating system to stage.") }
  }
}
