# == Class: jenkins::swarm_client
#
# This installs and configures the swarm client on a node.
class jenkins::swarm_client(
  $labels=undef,
  $master_address,
  $master_user=undef,
  $master_pass=undef,
) {
  include java

  if $kernel == 'Darwin' {
    $user = params_lookup('mac_login_user', 'global')
    $group = 'wheel'
    $sudo_run = false

    if $user == '' {
      fail("mac_login_user must be set.")
    }
  } else {
    $user = 'jenkins-swarm'
    $group = 'jenkins-swarm'
    $sudo_run = true
  }

  $client_path = '/usr/local/bin/jenkins-swarm.jar'
  $client_url = 'http://maven.jenkins-ci.org/content/repositories/releases/org/jenkins-ci/plugins/swarm-client/1.7/swarm-client-1.7-jar-with-dependencies.jar'

  $home_directory = $operatingsystem ? {
    'Darwin' => "/Users/${user}",
    default  => "/home/${user}",
  }

  $swarm_dir = "/var/lib/jenkins-swarm"
  $swarm_log_dir = "/var/log/jenkins-swarm"

  $script_run = '/usr/local/bin/jenkins_swarm_run'

  if $kernel == 'Linux' {
    #--------------------------------------------------------------------
    # User/Group for Jenkins
    #--------------------------------------------------------------------

    group { $group:
      ensure => present,
    }

    user { $user:
      ensure     => present,
      gid        => $group,
      home       => $home_directory,
      shell      => "/bin/bash",
      require    => Group[$group],
    }

    util::recursive_directory { $home_directory: }

    file { $home_directory:
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => '0755',
      require => [
        Group[$group],
        User[$user],
        Util::Recursive_directory[$home_directory],
      ],
    }
  } else {
    group { $group:
      ensure => present,
    }

    user { $user:
      ensure => present,
    }
  }

  #--------------------------------------------------------------------
  # Directories
  #--------------------------------------------------------------------
  util::recursive_directory { $swarm_dir: }
  util::recursive_directory { $swarm_log_dir: }

  file { $swarm_dir:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => [
      Group[$group],
      User[$user],
      Util::Recursive_directory[$swarm_dir],
    ],
  }

  file { $swarm_log_dir:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => [
      Group[$group],
      User[$user],
      Util::Recursive_directory[$swarm_log_dir],
    ],
  }

  #--------------------------------------------------------------------
  # Swarm Client
  #--------------------------------------------------------------------
  # Install the client
  download { 'jenkins-swarm-client':
    source      => $client_url,
    destination => $client_path,
  }

  # Install the runner
  util::script { $script_run:
    content => template('jenkins/swarm_client/script_run.erb'),
    require => [
      Class['java'],
      Download['jenkins-swarm-client'],
      File[$swarm_dir],
      User[$user],
    ],
  }

  #--------------------------------------------------------------------
  # Service
  #--------------------------------------------------------------------

  case $operatingsystem {
    'Archlinux': {
      file { "/etc/systemd/system/jenkins-swarm.service":
        ensure  => present,
        content => template("jenkins/swarm_client/systemd.erb"),
        owner   => "root",
        group   => "root",
        mode    => "0644",
        require => [
          File[$swarm_log_dir],
          Util::Script[$script_run],
        ],
      }

      service { 'jenkins-swarm':
        ensure    => running,
        provider  => systemd,
        require   => File["/etc/systemd/system/jenkins-swarm.service"],
        subscribe => Util::Script[$script_run],
      }
    }

    'CentOS', 'Ubuntu': {
      # Both CentOS and Ubuntu use Upstart...
      upstart { 'jenkins-swarm':
        content => template('jenkins/swarm_client/upstart.erb'),
        require => [
          File[$swarm_log_dir],
          Util::Script[$script_run],
        ],
      }

      # But Puppet on CentOS doesn't support the "upstart" provider,
      # so we have to do some hackery.
      if $operatingsystem == 'CentOS' {
        service { 'jenkins-swarm':
          ensure     => running,
          hasstatus  => true,
          hasrestart => true,
          restart    => '/sbin/initctl restart jenkins-swarm',
          start      => '/sbin/initctl start jenkins-swarm',
          stop       => '/sbin/initctl stop jenkins-swarm',
          status     => '/sbin/initctl status jenkins-swarm | grep "/running" 1>/dev/null 2>&1',
          require    => Upstart['jenkins-swarm'],
          subscribe => Util::Script[$script_run],
        }
      } else {
        # Normal upstart service for Ubuntu
        service { 'jenkins-swarm':
          ensure   => running,
          provider => upstart,
          require  => Upstart['jenkins-swarm'],
          subscribe => Util::Script[$script_run],
        }
      }
    }

    'Darwin': {
      $launchd_path = "/Library/LaunchDaemons/org.jenkins.jenkins-swarm.plist"

      launchd { "org.jenkins.jenkins-swarm":
        content => template('jenkins/swarm_client/launchd.erb'),
        notify  => Exec["restart-launchd-service"],
      }

      exec { "enable-launchd-service":
        command => "launchctl load ${launchd_path}",
        unless  => "launchctl list | grep org.jenkins.jenkins-swarm$",
        require => Launchd["org.jenkins.jenkins-swarm"],
      }

      exec { "restart-launchd-service":
        command     => "launchctl unload ${launchd_path} && sleep 3 && launchctl load ${launchd_path}",
        refreshonly => true,
        before      => Exec["enable-launchd-service"],
        require     => Launchd["org.jenkins.jenkins-swarm"],
        subscribe   => Util::Script[$script_run],
      }
    }

    default: {
      fail("Unknown OS to make service for.")
    }
  }
}
