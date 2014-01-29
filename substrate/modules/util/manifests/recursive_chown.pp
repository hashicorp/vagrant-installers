# == Define: recursive_chown
#
# This will ensure that a directory is properly owned by the right
# set of people.
#
define util::recursive_chown(
  $directory,
  $group,
  $owner
) {
  exec { "chown-${name}":
    command => "/bin/chown -R ${owner}:${group} ${directory}",
    onlyif  => "/usr/bin/stat --format=\"%U:%G\" ${directory}/* | grep -v ^${owner}:${group}$",
  }
}
