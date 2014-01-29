# == Class: sudo
#
# This configures sudo.
#
class sudo {
  include sudo::params

  $conf_dir = $sudo::params::conf_dir

  $root_user = "root"
  $root_group = $operatingsystem ? {
    "Darwin" => "wheel",
    default  => "root",
  }

  file { $conf_dir:
    ensure => directory,
    owner  => $root_user,
    group  => $root_group,
    mode   => "0755",
  }

  file { "/etc/sudoers":
    content => template("sudo/sudoers.erb"),
    owner   => $root_user,
    group   => $root_group,
    mode    => "0440",
    require => File[$conf_dir],
  }
}
