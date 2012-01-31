# Requirements for fog
if platform?("arch")
  package "libxml2"
  package "libxslt"
elsif platform("ubuntu")
  package "libxml2-dev"
  package "libxslt1-dev"
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


