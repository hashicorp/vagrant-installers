# Globally set the exec path because that is really annoying.
Exec {
  path => ["/bin", "/sbin" , "/usr/bin", "/usr/sbin", "/usr/local/bin"],
}

# Build the installer
include vagrant_installer
