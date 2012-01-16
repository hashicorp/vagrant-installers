# Install the 7-zip MSI
windows_package node[:sevenzip][:package_name] do
  source node[:sevenzip][:url]
  checksum node[:sevenzip][:checksum]
  options "INSTALLDIR=\"#{node[:sevenzip][:home]}\""
  action :install
end

# Update the PATH to add 7-zip
windows_path node[:sevenzip][:home]
