# == Define: script
#
# This will create an executable script. This is useful for quickly creating
# bash scripts and so on.
#
define util::script($path=$name, $content) {
  file { $path:
    ensure  => present,
    content => $content,
    owner   => "root",
    group   => "root",
    mode    => "0755",
  }
}
