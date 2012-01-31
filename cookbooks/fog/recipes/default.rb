# Requirements for fog
if platform?("arch")
  package "libxml2"
  package "libxslt"
elsif platform?("ubuntu")
  package "libxml2-dev"
  package "libxslt1-dev"
elsif platform?("centos")
  package "libxml2"
  package "libxml2-devel"
  package "libxslt"
  package "libxslt-devel"
elsif platform?("mac_os_x")
  # Already have the deps
else
  raise "I don't know how to build Fog on this platform."
end

# Install fog
gem_package "fog"

# Reset the gem path and load the fog gem
ruby_block "reset-gem-for-fog" do
  block do
    Gem.clear_paths
    require 'fog'
  end
end


