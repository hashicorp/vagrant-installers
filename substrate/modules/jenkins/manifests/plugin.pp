# == Define: jenkins::plugin
#
# This installs a Jenkins plugin.
#
define jenkins::plugin($plugin_name=$name) {
  include jenkins

  $url = "${jenkins::plugin_mirror}/latest/${plugin_name}.hpi"
  $destination = "${jenkins::plugin_dir}/${plugin_name}.hpi"

  wget::fetch { "jenkins-plugin-${name}":
    source      => $url,
    destination => $destination,
    require     => File[$jenkins::plugin_dir],
    notify      => Service['jenkins'],
  }

  file { $destination:
    ensure  => present,
    owner   => $jenkins::user,
    group   => $jenkins::group,
    mode    => '0644',
    require => Wget::Fetch["jenkins-plugin-${name}"],
    before  => Service['jenkins'],
  }
}
