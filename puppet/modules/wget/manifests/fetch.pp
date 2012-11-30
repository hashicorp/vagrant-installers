# == Define: wget::fetch
#
# This will download the given file to the given location using wget.
#
define wget::fetch($source=$name, $destination) {
  include wget

  exec { "wget-${name}":
    command => "/usr/bin/wget --output-document=${destination} ${source}",
    creates => $destination,
    timeout => 1200,
    require => Class["wget"],
  }
}
