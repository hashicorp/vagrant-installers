def action_compile
  # Setup the variables used for configuring compilation
  config_flags = ["--prefix=#{node[:isolated][:dir]}"] + new_resource.config_flags
  directory = new_resource.directory || new_resource.file.gsub(".tar.gz", "")
  env_vars  = cflags

  new_resource.environment.each do |key, value|
    env_vars[key] = "" if !env_vars[key]
    env_vars[key] += " #{value}"
  end

  # Upload the source package
  cookbook_file "#{Chef::Config[:file_cache_path]}/#{new_resource.file}"

  # Extract the source package
  execute "#{new_resource.name}-untar" do
    command "tar xvzf #{new_resource.file}"
    cwd Chef::Config[:file_cache_path]
  end

  # Run "./configure" with the proper flags
  execute "#{new_resource.name}-configure" do
    command "./configure #{config_flags.join(" ")}"
    cwd "#{Chef::Config[:file_cache_path]}/#{directory}"
    environment env_vars
  end

  # Compile!
  execute "#{new_resource.name}-make" do
    command "make"
    cwd "#{Chef::Config[:file_cache_path]}/#{directory}"
    environment env_vars
  end

  # Install
  execute "#{new_resource.name}-make-install" do
    command "make install"
    cwd "#{Chef::Config[:file_cache_path]}/#{directory}"
    environment env_vars
  end
end
