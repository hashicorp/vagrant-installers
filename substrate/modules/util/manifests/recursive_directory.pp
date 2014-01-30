# == Define: recursive_directory
#
# This will create a directory recursively IF it has never been created
# before. This is useful if you're trying to create a directory before
# the actual software module creates it. More concrete example follows:
#
# Example: If you have a piece of software, let's say PostgreSQL, that needs
# a data directory. You configure that data directory to be at "/data/pg."
# The `postgresql` Puppet module creates this directory with the proper
# permissions and all that, BUT you want that directory to be an EBS-mounted
# directory. However, to `/sbin/mount` a directory, it needs to exist first!
# See the chicken and egg problem? This definition will use `mkdir -p` to
# recursively create the directories (as root) if it has to. After this,
# other Puppet resources are expected to set the proper owner/group later
# in the process.
#
define util::recursive_directory($dir=$name) {
  if $operatingsystem == 'windows' {
    $win_dir = regsubst($dir, '/', '\\', 'G')

    exec { $name:
      command => "cmd.exe /C IF NOT EXIST ${win_dir} MKDIR ${win_dir}",
    }
  } else {
    exec { $name:
      command => "mkdir -p ${dir}",
      path    => ["/bin", "/usr/bin"],
      unless  => "test -d ${dir}",
    }

    file { $name:
      ensure  => directory,
      mode    => "0755",
      require => Exec[$name],
    }
  }
}
