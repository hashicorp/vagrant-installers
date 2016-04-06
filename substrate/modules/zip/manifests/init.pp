class zip {
  case $operatingsystem {
    'CentOS': {
      package { "zip":
        ensure   => installed,
      }
    }

    'FreeBSD': {
      package { ["zip", "unzip"]:
        ensure   => installed,
        provider => pkgng,
      }
    }

    'Ubuntu': {
      package { ["zip", "unzip"]:
        ensure   => installed,
      }
    }
  }
}
