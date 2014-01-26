# == Class: bsdtar
#
# This compiles/installs bsdtar.
#
class bsdtar(
  $autotools_environment = {},
  $install_dir,
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
) {
  case $kernel {
    'Darwin', 'Linux', 'FreeBSD': { include bsdtar::posix }
    'windows': { include bsdtar::windows }
    default: { fail("Unknown operating system to install bsdtar.") }
  }
}
