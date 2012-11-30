# == Define: patch
#
# This uses `patch` to patch a set of files.
#
define patch($content, $prefixlevel, $cwd) {
  require patch::setup

  $patch_file = "/tmp/patch_${name}"

  file { $patch_file:
    ensure  => present,
    content => $content,
    owner   => "root",
    group   => "root",
    mode    => "0644",
  }

  exec { "patch-${name}":
    command => "patch -p${prefixlevel} -i ${patch_file}",
    cwd     => $cwd,
    require => File[$patch_file],
  }
}
