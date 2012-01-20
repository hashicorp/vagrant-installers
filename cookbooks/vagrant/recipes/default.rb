require 'fileutils'

#----------------------------------------------------------------------
# Gem creation
#
# This is all done at compilation time so that we know the gem version,
# we know it builds properly, etc.
#----------------------------------------------------------------------
# Check out the source
checkout_path = ::File.join(Chef::Config[:file_cache_path], "vagrant-src")
git checkout_path do
  repository node[:vagrant][:repository]
  revision   node[:vagrant][:revision]
  action     :nothing
end.run_action(:sync)

# Build the gem
execute "vagrant-gem-build" do
  command "gem build vagrant.gemspec"
  cwd     checkout_path
  action  :nothing
end.run_action(:run)

# Set this variable so that the sub-recipes can access it
node[:vagrant][:gem_path] = ::File.join(Chef::Config[:file_cache_path], "vagrant.gem")

# Find the built gem, which is the latest "gem" file in the source
built_gem_path = ::Dir[::File.join(checkout_path, "vagrant-*.gem")]
built_gem_path = built_gem_path.sort_by{|f| ::File.mtime(f)}.last

# Copy it over
FileUtils.cp(built_gem_path, node[:vagrant][:gem_path])

# Set the version on our node so we can use it later
gem_name = ::File.basename(built_gem_path, ".gem")
version  = gem_name.split("-").last
node[:vagrant][:version] = version.gsub(".dev", "")

Chef::Log.info("Building installers for Vagrant v#{node[:vagrant][:version]}")

# Bring in the tasks that install the gem into the environment, which is
# done during actual convergence
if platform?("windows")
  include_recipe "vagrant::windows"
else
  include_recipe "vagrant::linux"
end
