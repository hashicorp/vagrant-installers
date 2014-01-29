# == Class: rubyencoder::loaders
#
# This installs the RubyEncoder loaders.
#
# === Parameters
#
# * `path` - Path to where to put the "rgloaders" directory. This path
#   must exist.
#
class rubyencoder::loaders(
  $path
) {
  if $kernel == 'Linux' {
    # Make sure the permissions are set properly
    $owner = "root"
    $group = "root"
    $mode  = "0644"
  } elsif $kernel == 'Darwin' {
    $owner = "root"
    $group = "wheel"
    $mode  = "0644"
  } else {
    $owner = undef
    $group = undef
    $mode  = undef
  }

  file { "${path}/rgloader":
    source  => "puppet:///modules/rubyencoder/rgloader",
    recurse => true,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
  }
}
