class zip {
  case $operatingsystem {
    'CentOS': {
      package { "zip":
        ensure => installed,
      }
    }

    'Ubuntu': {
      package { ["zip", "unzip"]:
        ensure => installed,
      }
    }
  }
}
