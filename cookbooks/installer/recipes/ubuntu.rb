# Update the mirror list
execute "refresh-apt" do
  command "apt-get update"
end

# Some dependencies for Ruby extensions we want installed
include_recipe "libffi"
include_recipe "libyaml"
include_recipe "zlib"
include_recipe "openssl"
include_recipe "readline"

# The actual dependencies of Vagrant
include_recipe "ruby"
include_recipe "vagrant"
include_recipe "package"
