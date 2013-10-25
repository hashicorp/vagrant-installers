# == Define: wget::fetch
#
# This will download the given file to the given location using wget.
#
# === Parameters
#
# [*namevar*]
#   Equivalent to `source`.
#
# [*source*]
#   The URL of the file. This can be anything that wget accepts (HTTP,
#   FTP, etc.)
#
# [*destination*]
#   The path where the file will be saved.
#
define wget::fetch($source=$name, $destination) {
  require wget

  exec { "wget-${name}":
    command => "wget --no-check-certificate --output-document=${destination} ${source}",
    creates => $destination,
    timeout => 1200,
    path    => $::path,
  }
}
