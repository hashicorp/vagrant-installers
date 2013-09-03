# == Class: java
#
# This installs Java on the machine.
#
class java {
  case $operatingsystem {
    'Archlinux': {
      package { ["jre7-openjdk", "jdk7-openjdk"]:
        ensure => installed,
      }
    }

    'CentOS': {
      package { ["java-1.7.0-openjdk", "java-1.7.0-openjdk-devel"]:
        ensure => installed,
      }
    }

    'Darwin': {
      # Assume installed from an outside source.
    }

    'Ubuntu': {
      package { ['openjdk-7-jdk', 'openjdk-7-jre-headless']:
        ensure => installed,
      }
    }

    default: {
      fail("Unknown operatingsystem to install Java.")
    }
  }
}
