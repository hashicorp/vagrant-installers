include_recipe "wix"

# The directory where we will build up the package
pkg_dir = node[:package][:output_dir]

# The component group name for the files
files_component_group = "VagrantDir"

# Localization strings for the installer
wxl_path = ::File.join(pkg_dir, "vagrant-en-us.wxl")
template wxl_path do
  source "windows/en-us.wxl.erb"
  mode   0755
end

# The include file which has definitions for the rest
# of the installer.
wxi_path = ::File.join(pkg_dir, "vagrant-config.wxi")
template wxi_path do
  source "windows/config.wxi.erb"
  mode   0755
end

# The main source file to generate the installer
template ::File.join(pkg_dir, "vagrant-main.wxs") do
  source "windows/main.wxs.erb"
  mode   0755
  variables(
    :wxi_path => wxi_path,
    :files_component_group => files_component_group
  )
end

# Harvest the files we plan on installing with `heat.exe`
# This creates a `wxs` file that contains all the
# information about the files we want to copy.
windows_batch "harvest vagrant" do
  code <<-EOH
#{node[:wix][:home]}\\heat.exe ^
dir \"#{node[:installer][:staging_dir]}\" ^
-nologo -srd -gg ^
-cg #{files_component_group} ^
-dr VAGRANTLOCATION ^
-var var.VagrantSourceDir ^
-out #{pkg_dir}\\vagrant-files.wxs
  EOH
end

# Compile the installer. This step generates wixobj files
# which should be ready to link.
windows_batch "compile vagrant" do
  code <<-EOH
#{node[:wix][:home]}\\candle.exe ^
-nologo ^
-I#{pkg_dir} ^
-dVagrantSourceDir=\"#{node[:installer][:staging_dir]}\" ^
-out #{pkg_dir}\\ ^
#{pkg_dir}\\vagrant-files.wxs ^
#{pkg_dir}\\vagrant-main.wxs
  EOH
end

# Link the installer, generate an MSI
=begin
windows_batch "link vagrant" do
  code <<-EOH
#{node[:wix][:home]}\\light.exe ^
-nologo ^
-ext WixUIExtension ^
-cultures:en-us -loc #{pkg_dir}\\vagrant-en-us.wxl ^
-out #{dist_dir} ^
#{pkg_dir}\\vagrant-files.wixobj ^
#{pkg_dir}\\vagrant-main.wixobj
  EOH

  returns [0, 204]
end
=end
