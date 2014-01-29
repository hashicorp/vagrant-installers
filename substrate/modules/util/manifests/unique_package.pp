# == Define: util::unique_package
#
# This will make sure that a package resource is only created once.
define util::unique_package($package_name=$name) {
  if !defined(Package[$package_name]) {
    package { $package_name:
      ensure => installed,
    }
  }
}
