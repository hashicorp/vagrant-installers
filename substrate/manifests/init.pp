#--------------------------------------------------------------------
# Globally set the exec path because that is really annoying.
#--------------------------------------------------------------------
if $kernel == 'windows' {
  Exec {
    path => [
      "C:\\Windows\\System32",
      "C:\\Windows\\System32\\WindowsPowerShell\\v1.0",
    ],
  }
} else {
  Exec {
    path => ["/usr/local/bin", "/bin", "/sbin" , "/usr/bin", "/usr/sbin"],
  }
}

#--------------------------------------------------------------------
# Build the substrate
#--------------------------------------------------------------------
include vagrant_substrate
