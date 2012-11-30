class build_essential {
  package {
    ["build-essential", "autoconf", "automake", "libtool"]:
      ensure => installed,
  }
}
