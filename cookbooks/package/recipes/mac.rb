# Set the resulting file to be copied later
node[:package][:output] = ::File.join(node[:package][:output_dir],
                                      "Vagrant-#{node[:vagrant][:version]}.dmg")

#----------------------------------------------------------------------
# Temporary directory for creating the package stuff
#
# Most of the package building command line tools are heavily
# dependent on working directory and many intermediary files, so we
# need a place to put them. We put them in this "staging" directory.
#----------------------------------------------------------------------
pkg_staging_dir = ::File.join(Chef::Config[:file_cache_path], "pkg")
directory pkg_staging_dir do
  mode 0755
end

#----------------------------------------------------------------------
# PKG
#----------------------------------------------------------------------
# Variables
#
# This is the path to resources directory that will be used
# with `productbuild` to get our resources for the installer.
pkg_resources_dir = ::File.join(node[:package][:support_dir], "mac", "resources")

# This is the path where the distribution definition will live.
pkg_dist_path = ::File.join(pkg_staging_dir, "vagrant.dist")

# These are the command line options for pkgbuild
pkgbuild_options = [
  "--root", node[:installer][:staging_dir],
  "--identifier", "com.vagrant.vagrant",
  "--version", node[:vagrant][:version],
  "--install-location", node[:package][:mac][:install_location],
  "--scripts", ::File.join(node[:package][:support_dir], "mac", "scripts"),
  "--sign", "\"#{node[:package][:mac][:sign_name]}\""
]

# This is the final path for the core package
pkgbuild_output_path = ::File.join(pkg_staging_dir, "core.pkg")

# These are the command line options for productbuild
productbuild_options = [
  "--distribution", pkg_dist_path,
  "--resources", pkg_resources_dir,
  "--package-path", pkg_staging_dir,
  "--sign", "\"#{node[:package][:mac][:sign_name]}\""
]

# This is the final output path for the installer package
productbuild_output_path = ::File.join(node[:package][:output_dir], "Vagrant.pkg")

# First, create the component package using pkgbuild. The component
# package contains the raw file structure that is installed via the
# installer package.
execute "component-pkg" do
  command "pkgbuild #{pkgbuild_options.join(" ")} #{pkgbuild_output_path}"
end

# Create the distribution definition
template pkg_dist_path do
  source "mac/dist.erb"
  mode   0644
end

# Build the installer package
execute "installer-pkg" do
  command "productbuild #{productbuild_options.join(" ")} #{productbuild_output_path}"
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
# Build a support directory
support_directory = ::File.join(node[:package][:output_dir], ".support")
directory support_directory do
  mode 0755
end

cookbook_file ::File.join(support_directory, "background.png") do
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
  "FINAL_PATH" => node[:package][:output],
  "INSTALLER_NAME" => "Vagrant.pkg",
  "BG_FILENAME" => "background.png"
}

execute "build-dmg" do
  command script_path
  environment env_vars
end
