# The path where the installer will be outputted to
default[:package][:output_dir] = File.expand_path("../../../../dist", __FILE__)

# Mac PackageMaker options
default[:package][:packagemaker][:path] = "/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker"
default[:package][:packagemaker][:pmdoc] = File.expand_path("../../../../vagrant.pmdoc", __FILE__)
