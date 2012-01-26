# The path where the installer will be outputted to
default[:package][:output_dir] = File.expand_path("../../../../dist",
                                                  __FILE__)
default[:package][:support_dir] = File.expand_path("../../../../support",
                                                   __FILE__)

# Mac PackageMaker options
default[:package][:packagemaker][:path] = "/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker"
default[:package][:packagemaker][:pmdoc] = File.expand_path("../../../../vagrant.pmdoc", __FILE__)

# Windows options
default[:package][:win][:upgrade_code] = "1a672674-6722-4e3a-9061-8f539a8b0ed6"

# Debian options
default[:package][:debian][:prefix] = "/opt/vagrant"

# CentOS options
default[:package][:centos][:prefix] = "/opt/vagrant"
