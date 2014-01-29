# == Define: sudo::sudoer
#
# This creates a new rule for a sudoer.
#
define sudo::sudoer($content) {
  include sudo
  include sudo::params

  $conf_dir = $sudo::params::conf_dir

  $real_content = $content ? {
    ""      => "",
    default => "# Managed by Puppet\n${content}\n",
  }

  file { "${conf_dir}/${name}":
    content => $real_content,
    owner   => $sudo::root_user,
    group   => $sudo::root_group,
    mode    => "0440",
    require =>  File[$conf_dir],
  }
}
