# == Define: upstart
#
# Creates and manages upstart jobs.
#
# === Parameters
#
# [*content*]
#   This is the content that will go into the actual upstart file.
#
define upstart($content) {
  file { "/etc/init/${title}.conf":
    ensure  => present,
    content => $content,
    owner   => "root",
    group   => "root",
    mode    => "0644",
  }
}
