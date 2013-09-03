class ruby::binary::linux {
  package { "ruby":
    ensure => installed,
  }

  if $lsbdistid == 'Ubuntu' and $lsbmajdistrelease == '10' {
    # On Ubuntu 10 we need to install RubyGems from scratch, because
    # the one they have in packages are too old. We just use a script
    # for this because of laziness.
    util::script { "install-rubygems":
      path    => "/usr/local/bin/install_rubygems_from_source",
      content => template("ruby/install_rubygems_from_source.sh.erb"),
    }

    exec { "/usr/local/bin/install_rubygems_from_source":
      unless  => "test -f /usr/bin/gem",
      require => [
        Package["ruby"],
        Util::Script["install-rubygems"],
      ],
    }
  } elsif $operatingsystem != 'Archlinux' {
    package { "rubygems":
      ensure => installed,
    }
  }

  case $operatingsystem {
    'Archlinux': {
      # Arch installs a very annoying default gemrc file that has
      # "--user-install" as the default. Get rid of that.
      file { "/etc/gemrc":
        ensure  => absent,
        require => Package["ruby"],
      }
    }

    'CentOS': {
      package { "ruby-devel":
        ensure => latest,
      }
    }

    'Ubuntu': {
      package { "ruby-dev":
        ensure => installed,
      }
    }
  }
}
