env_vars = cflags.merge({
  "GEM_HOME" => "#{embedded_dir}/gems",
  "GEM_PATH" => "#{embedded_dir}/gems"
})

package_name = node[:vagrant][:gem_name]

if platform?("windows")
  # Make the path Windows-style if we're on Windows
  package_name = package_name.gsub("/", "\\")

  # Make the environment paths windows style as well
  env_vars["GEM_HOME"] = env_vars["GEM_HOME"].gsub("/", "\\")
  env_vars["GEM_PATH"] = env_vars["GEM_PATH"].gsub("/", "\\")
end

gem_package package_name do
  version "> 0"
  gem_binary "#{embedded_dir}/bin/gem"
end

if platform?("windows")
  # We need a little batch wrapper so that we execute the
  # bin in the context of our isolated Ruby.
  template "#{staging_dir}/bin/vagrant.bat" do
    source "bin_wrapper.bat.erb"
    mode   0755
    variables :bin => "vagrant"
  end
else
  # A linux wrapper that sets the proper GEM_HOME/GEM_PATH
  # data so that it is also executed in the correct context
  template "#{staging_dir}/bin/vagrant" do
    source "vagrant.erb"
    mode 0755
  end
end
