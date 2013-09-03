# == Class: ntp
#
# This installs and configures NTP.
#
class ntp {
  case $operatingsystem {
    'CentOS': {
      $service_name     = "ntpd"
      $service_provider = "init"

      package { "ntp":
        ensure => installed,
        before => Service["ntp"],
      }
    }

    'Ubuntu': {
      $service_name = "ntp"

      package { ["ntp", "ntpdate"]:
        ensure => installed,
        before => Service["ntp"],
      }
    }
  }

  service { $service_name:
    ensure   => running,
    enable   => true,
    provider => $service_provider,
    alias    => "ntp",
  }
}
