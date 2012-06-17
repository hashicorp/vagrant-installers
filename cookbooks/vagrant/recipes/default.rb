require 'fileutils'

# Variables used throughout the process in this file
gem_file         = ::File.join(Chef::Config[:file_cache_path], "vagrant.gem")
gem_version_file = ::File.join(Chef::Config[:file_cache_path], "vagrant.gem.version")
rev_file         = ::File.join(Chef::Config[:file_cache_path], "vagrant-rev")
checkout_path    = ::File.join(Chef::Config[:file_cache_path], "vagrant-src")

# Set up some node attributes so that other recipes can access it
node[:vagrant][:gem_path] = gem_file

#----------------------------------------------------------------------
# Gem creation
#
# This is all done at compilation time so that we know the gem version,
# we know it builds properly, etc.
#----------------------------------------------------------------------
Chef::Log.info("Packaging Vagrant from revision: #{node[:vagrant][:revision]}")

# Only checkout if we have never checked out before, or if we checked out
# the incorrect revision.
do_checkout = false
begin
  do_checkout = ::File.read(rev_file) != node[:vagrant][:revision]

  if do_checkout
    Chef::Log.info("Revisions of Vagrant version didn't match. Checking out from git...")
  else
    Chef::Log.info("Using cached download of Vagrant source.")
  end
rescue Errno::ENOENT
  Chef::Log.info("Never checked out Vagrant, checking it out...")
  do_checkout = true
end

if do_checkout
  # Delete the old checkout path in case it exists
  directory checkout_path do
    recursive true
    action    :nothing
  end.run_action(:delete)

  # Delete the old gem file to force a rebuild
  file gem_file do
    action :nothing
  end.run_action(:delete)

  # Check out the source to the directory
  git checkout_path do
    repository node[:vagrant][:repository]
    revision   node[:vagrant][:revision]
    action     :nothing
  end.run_action(:sync)

  # Setup the contents of the rev file
  file rev_file do
    content node[:vagrant][:revision]
    mode    0644
    action  :nothing
  end.run_action(:create)
end

# Build the gem if the gem file doesn't exist
if !::File.exist?(gem_file)
  # Build the gem
  execute "vagrant-gem-build" do
    command "gem build vagrant.gemspec"
    cwd     checkout_path
    action  :nothing
  end.run_action(:run)

  # Find the built gem, which is the latest "gem" file in the source
  built_gem_path = ::Dir[::File.join(checkout_path, "vagrant-*.gem")]
  built_gem_path = built_gem_path.sort_by{|f| ::File.mtime(f)}.last

  # Copy it over
  FileUtils.cp(built_gem_path, gem_file)

  # Set the version on our node so we can use it later
  gem_name = ::File.basename(built_gem_path, ".gem")
  version  = gem_name.split("-").last
  version  = version.gsub(".dev", "")

  # Store the version in the version file
  file gem_version_file do
    content version
    mode    0644
  end.run_action(:create)
end

# Set the version on our node attributes so that we can use it later
node[:vagrant][:version] = ::File.read(gem_version_file)

#----------------------------------------------------------------------
# Instal Vagrant
#----------------------------------------------------------------------
Chef::Log.info("Building installers for Vagrant v#{node[:vagrant][:version]}")

# Bring in the tasks that install the gem into the environment, which is
# done during actual convergence
if platform?("windows")
  include_recipe "vagrant::windows"
else
  include_recipe "vagrant::linux"
end
