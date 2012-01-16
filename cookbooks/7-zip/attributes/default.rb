default[:sevenzip][:home] = "#{ENV["SYSTEMDRIVE"]}\\sevenzip"

# The sevenzip installation is different depending on if we're
# on a 64 or 32-bit kernel.
if kernel["machine"] =~ /x86_64/
  default[:sevenzip][:url] = "http://downloads.sourceforge.net/sevenzip/7z920-x64.msi"
  default[:sevenzip][:checksum] = "62df458bc521001cd9a947643a84810ecbaa5a16b5c8e87d80df8e34c4a16fe2"
  default[:sevenzip][:package_name] = "7-Zip 9.20 (x64 Edition)"
else
  default[:sevenzip][:url] = "http://downloads.sourceforge.net/sevenzip/7z920.msi"
  default[:sevenzip][:checksum] = "fe4807b4698ec89f82de7d85d32deaa4c772fc871537e31fb0fccf4473455cb8"
  default[:sevenzip][:package_name] = "7-Zip 9.20"
end
