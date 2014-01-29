# == Class: vagrant_installer
#
# This creates a Vagrant installer for the platform that this is
# run on.
#
class vagrant_installer {
  #------------------------------------------------------------------
  # Run stages
  #------------------------------------------------------------------
  stage { "prepare": before => Stage["main"] }
  stage { "package": }

  Stage["main"] -> Stage["package"]

  #------------------------------------------------------------------
  # Classes
  #------------------------------------------------------------------
  class { "vagrant_installer::prepare":
    stage => "prepare",
  }

  class { "vagrant_installer::staging": }

  class { "vagrant_installer::package":
    stage => "package",
  }
}
