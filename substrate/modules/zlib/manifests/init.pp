# == Class: zlib
#
# This class installs zlib from source.
#
class zlib(
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $make_notify = undef,
  $install_dir = undef,
  $target_arch = undef,
  $prefix = params_lookup('prefix'),
) {
  case $kernel {
    'Darwin', 'Linux': { include zlib::posix }
    default: { fail("Unknown OS to install zlib") }
  }
}
