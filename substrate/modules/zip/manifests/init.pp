class zip {
  case $operatingsystem {
    'Ubuntu': {
      package { ["zip", "unzip"]:
        ensure => installed,
      }
    }
  }
}
