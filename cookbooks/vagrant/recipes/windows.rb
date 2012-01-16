# Make the path Windows-style if we're on Windows
package_name = node[:vagrant][:gem_path].gsub("/", "\\")

# Make the environment paths windows style as well
env_vars["GEM_HOME"] = env_vars["GEM_HOME"].gsub("/", "\\")
env_vars["GEM_PATH"] = env_vars["GEM_PATH"].gsub("/", "\\")

gem_package package_name do
  version "> 0"
  gem_binary "#{embedded_dir}/bin/gem"
end

# We need a little batch wrapper so that we execute the
# bin in the context of our isolated Ruby.
template "#{staging_dir}/bin/vagrant.bat" do
  source "bin_wrapper.bat.erb"
  mode   0755
  variables :bin => "vagrant"
end
