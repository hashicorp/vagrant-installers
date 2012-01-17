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
