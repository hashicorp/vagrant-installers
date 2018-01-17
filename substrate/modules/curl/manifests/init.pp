# == Class: curl
#
# This installs cURL.
#
class curl(
  $autotools_environment = {},
  $install_dir,
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $target_arch = undef,
) {
  case $kernel {
    'Darwin', 'Linux': { include curl::posix }
    default: { fail("Unknown OS to install cURL") }
  }
}
