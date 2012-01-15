# This is the path to the "PackageMaker" CLI. This is typically where it
# is and depends on XCode being installed.
default[:installer][:packagemaker][:path] = "/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker"
default[:installer][:packagemaker][:pmdoc] = File.expand_path("../../../../vagrant.pmdoc", __FILE__)
