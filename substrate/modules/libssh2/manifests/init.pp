# == Class: libssh2
#
# This installs the libssh2 library from source.
#
class libssh2(
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $make_notify = undef,
  $prefix = params_lookup('prefix'),
  $target_arch = undef,
  $install_dir = undef,
) {
  case $kernel {
    'Darwin', 'Linux': { include libssh2::posix }
    default: { fail("Unknown OS to install libssh2") }
  }
}
