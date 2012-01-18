require 'fileutils'

#----------------------------------------------------------------------
# Gem creation
#----------------------------------------------------------------------
# Check out the source
checkout_path = ::File.join(Chef::Config[:file_cache_path], "vagrant-src")
git checkout_path do
  repository node[:vagrant][:repository]
  revision   node[:vagrant][:revision]
  action     :sync
end

# Build the gem
execute "vagrant-gem-build" do
  command "gem build vagrant.gemspec"
  cwd     checkout_path
end

# Set this variable so that the sub-recipes can access it
node[:vagrant][:gem_path] = ::File.join(Chef::Config[:file_cache_path], "vagrant.gem")

# Copy the gem to the file cache.
ruby_block "copy-built-gem" do
  block do
    # Find the built gem, which is the latest "gem" file in the source
    built_gem_path = ::Dir[::File.join(checkout_path, "vagrant-*.gem")]
    built_gem_path = built_gem_path.sort_by{|f| ::File.mtime(f)}.last

    # Copy it over
    FileUtils.cp(built_gem_path, node[:vagrant][:gem_path])

    # Set the version on our node so we can use it later
    gem_name = ::File.basename(built_gem_path, ".gem")
    version  = gem_name.split("-").last
    node[:vagrant][:version] = version.gsub(".dev", "")
  end
end

if platform?("windows")
  include_recipe "vagrant::windows"
else
  include_recipe "vagrant::linux"
end
