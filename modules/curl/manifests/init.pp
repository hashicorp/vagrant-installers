# == Class: curl
#
# This installs cURL.
#
class curl(
  $autotools_environment = {},
  $install_dir,
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
) {
  case $kernel {
    'Darwin', 'Linux', 'FreeBSD': { include curl::posix }
    'windows':         { include curl::windows }
    default: { fail("Unknown OS to install cURL") }
  }
}
