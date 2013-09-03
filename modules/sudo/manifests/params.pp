# == Class: sudo::params
#
# This includes many parameters for sudo.
#
class sudo::params {
  $conf_dir = hiera("sudo_conf_dir", "/etc/sudoers.d")
}
