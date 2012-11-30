class build_essential {
  if $operatingsystem == 'Ubuntu' {
    package {
      ["build-essential", "autoconf", "automake", "libtool"]:
        ensure => installed,
    }
  }
}
