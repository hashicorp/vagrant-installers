# == Define: download
#
# This downloads a file from source to destination. This works cross-platform
# on both Windows, Mac, and Linux.
#
define download($source, $destination) {
  case $kernel {
    'Darwin', 'Linux', 'FreeBSD': {
      # On Mac, Linux, and FreeBSD we use wget
      wget::fetch { $name:
        source      => $source,
        destination => $destination,
      }
    }

    'windows': {
      # On Windows we do some crazy PowerShell fun.
      powershell { "download-${name}":
        content => template("download/powershell.erb"),
        creates => $destination,
      }
    }
  }
}
