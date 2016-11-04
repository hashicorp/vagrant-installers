# == Define: homebrew::package
#
# This installs a package with homebrew.
#
define homebrew::package(
  $link=false,
  $package=$name,
  $creates=undef,
) {
  require homebrew
  include homebrew::params

  $user = $homebrew::params::user

  exec { "brew install ${package}":
    creates     => $creates,
    environment => "HOME=/Users/${user}",
    user        => $user,
    timeout     => 1200
  }

  if $link {
    exec { "brew link ${package}":
      creates     => $creates,
      environment => "HOME=/Users/${user}",
      subscribe   => Exec["brew install ${package}"],
      user        => $user,
    }
  }
}
