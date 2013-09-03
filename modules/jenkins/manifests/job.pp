# == Define: jenkins::job
#
# This creates a jenkins job with the given name and configuration.j
#
define jenkins::job($job_name=$name, $config) {
  include jenkins

  $jobs_dir = "${jenkins::home_dir}/jobs"
  $this_dir = "${jobs_dir}/${job_name}"

  if !defined(File[$jobs_dir]) {
    file { $jobs_dir:
      ensure  => directory,
      owner   => $jenkins::user,
      group   => $jenkins::group,
      mode    => '0755',
      require => Package['jenkins'],
    }
  }

  file { $this_dir:
    ensure  => directory,
    owner   => $jenkins::user,
    group   => $jenkins::group,
    mode    => '0755',
    require => [
      File[$jobs_dir],
      Package['jenkins'],
    ],
  }

  file { "${this_dir}/config.xml":
    ensure  => present,
    content => $config,
    owner   => $jenkins::user,
    group   => $jenkins::group,
    mode    => '0644',
    require => [
      File[$this_dir],
      Package['jenkins'],
    ],
    notify => Service['jenkins'],
  }
}
