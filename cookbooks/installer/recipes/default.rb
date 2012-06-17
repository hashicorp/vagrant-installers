#----------------------------------------------------------------------
# Setup the directories
#----------------------------------------------------------------------
# Make sure the file cache exists. We do this during the compilation
# phase since the git checkout (which also happens during the compilation
# phase) depends on this.
directory Chef::Config[:file_cache_path] do
  mode 0755
  recursive true
  action :nothing
end.run_action(:create)

# We delete the staging directory first so that every time we build
# an installer we have a fresh directory that doesn't have any cruft
# that may be left over from the last build.
directory node[:installer][:staging_dir] do
  recursive true
  action :delete
end

# Create the directories which will store our staging environment
# that we use to package the installer.
["", "bin", "embedded"].each do |subdir|
  directory ::File.join(node[:installer][:staging_dir], subdir) do
    mode  0755
    recursive true
  end
end

#----------------------------------------------------------------------
# Obtain File Lock
#----------------------------------------------------------------------
# We do this so that only one build can run at any given time.
$_chef_lock_file = File.open(File.join(Chef::Config[:file_cache_path], "chef_lock"), "w+")
if $_chef_lock_file.flock(File::LOCK_EX | File::LOCK_NB) === false
  $_chef_lock_file = nil
  Chef::Log.info("Another Chef process running. Not running.")
  exit(true)
end

# Unlock the file at exit, just to be sure
at_exit do
  if $_chef_lock_file
    $_chef_lock_file.flock(File::LOCK_UN)
    $_chef_lock_file = nil
  end
end

#----------------------------------------------------------------------
# Options, options, options
#----------------------------------------------------------------------
# If we specify a revision with an environmental variable, then we should
# use that instead
if ENV["VAGRANT_REVISION"]
  node[:vagrant][:revision] = ENV["VAGRANT_REVISION"]
end

# AWS settings
if ENV["AWS"]
  parts = ENV["AWS"].split(",")
  node[:upload][:aws_access_key_id]     = parts[0]
  node[:upload][:aws_secret_access_key] = parts[1]
  node[:upload][:bucket]                = parts[2]
end

#----------------------------------------------------------------------
# Platform-specific stuff
#----------------------------------------------------------------------
if platform?("mac_os_x")
  include_recipe "installer::mac"
elsif platform?("windows")
  include_recipe "installer::windows"
elsif platform?("ubuntu")
  include_recipe "installer::ubuntu"
elsif platform?("centos")
  include_recipe "installer::centos"
elsif platform?("arch")
  include_recipe "installer::arch"
else
  raise "Unsupported platform: #{node[:platform]}"
end

#----------------------------------------------------------------------
# Upload the package that was created
#----------------------------------------------------------------------
# If the "NO_UPLOAD" environmental variable is set, the we don't
# upload the installer.
include_recipe "upload" if !ENV["NO_UPLOAD"]
