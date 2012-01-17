#----------------------------------------------------------------------
# PKG
#----------------------------------------------------------------------
execute "mac-pkg" do
  command "#{node[:package][:packagemaker][:path]} -v -d #{node[:package][:packagemaker][:pmdoc]} -o #{node[:package][:output_dir]}/Vagrant.pkg"
end

#----------------------------------------------------------------------
# Uninstall Script
#----------------------------------------------------------------------
uninstall_path = ::File.join(node[:package][:output_dir], "uninstall.tool")
cookbook_file uninstall_path do
  source "uninstall.tool"
  mode 0755
end

#----------------------------------------------------------------------
# DMG
#----------------------------------------------------------------------
# Copy in the background image to the output
background_directory = ::File.join(node[:package][:output_dir], ".background")
directory background_directory do
  mode 0755
end

cookbook_file ::File.join(background_directory, "background.png") do
  source "background.png"
  mode   0644
end

# Upload the script to build it
script_path = ::File.join(Chef::Config[:file_cache_path], "dmg.sh")
cookbook_file script_path do
  source "dmg.sh"
  mode   0755
end

# Run it!
env_vars = {
  "TITLE" => "Vagrant",
  "SOURCE" => node[:package][:output_dir],
  "SIZE"   => "102400",
  "TEMP_PATH" => ::File.join(Chef::Config[:file_cache_path], "temp.dmg"),
  "FINAL_PATH" => ::File.join(node[:package][:output_dir], "Vagrant.dmg"),
  "INSTALLER_NAME" => "Vagrant.pkg",
  "BG_FILENAME" => "background.png"
}

execute "build-dmg" do
  command script_path
  environment env_vars
end
