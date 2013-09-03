# == Class: jenkins
#
# This installs Jenkins.
#
class jenkins {
  $home_dir = '/var/lib/jenkins'
  $plugin_dir = "${home_dir}/plugins"
  $plugin_mirror = "http://updates.jenkins-ci.org"

  $user = 'jenkins'
  $group = 'nogroup'

  apt::key { 'jenkins':
    key_id => 'D50582E6',
  }

  apt::repository { 'jenkins':
    content => "deb http://pkg.jenkins-ci.org/debian binary/\n",
    require => Apt::Key['jenkins'],
  }

  package { 'jenkins':
    ensure  => installed,
    require => Apt::Repository['jenkins'],
  }

  # The Jenkins service itself will create the plugin dir but we do so
  # explicitly here because it takes some time and the plugins need it
  # right away.
  file { $plugin_dir:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => Package['jenkins'],
  }

  service { 'jenkins':
    ensure  => running,
    status  => "/etc/init.d/jenkins status | grep 'not running'; test $? -eq 1",
    require => Package['jenkins'],
  }
}
