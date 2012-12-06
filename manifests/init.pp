# Globally set the exec path because that is really annoying.
if $kernel == 'windows' {
  Exec {
    path => [
      "C:\\Windows\\System32",
      "C:\\Windows\\System32\\WindowsPowerShell\\v1.0",
    ],
  }
} else {
  Exec {
    path => ["/bin", "/sbin" , "/usr/bin", "/usr/sbin", "/usr/local/bin"],
  }
}

# Build the installer
include vagrant_installer
