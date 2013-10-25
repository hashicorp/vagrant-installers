class zip {
  case $operatingsystem {
    'Ubuntu': {
      package { ["zip", "unzip"]:
        ensure   => installed,
      }
    }
    'FreeBSD': {
      package { ["zip", "unzip"]:
        ensure   => installed,
        provider => pkgng,
      }
    }
  }
}
