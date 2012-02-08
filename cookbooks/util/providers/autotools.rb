def action_compile
  # Setup the variables used for configuring compilation
  config_flags = ["--prefix=#{embedded_dir}"] + new_resource.config_flags
  env_vars  = compute_env_vars

  # Upload the source package
  cookbook_file "#{Chef::Config[:file_cache_path]}/#{new_resource.file}"

  # Extract the source package
  execute "#{new_resource.name}-untar" do
    command "tar xvzf #{new_resource.file}"
    cwd Chef::Config[:file_cache_path]
  end

  # Run "./configure" with the proper flags
  execute "#{new_resource.name}-configure" do
    command "./#{new_resource.config_file} #{config_flags.join(" ")}"
    cwd "#{Chef::Config[:file_cache_path]}/#{directory}"
    environment env_vars
  end

  # Compile!
  execute "#{new_resource.name}-make" do
    command "make"
    cwd "#{Chef::Config[:file_cache_path]}/#{directory}"
    environment env_vars
  end
end

def action_install
  env_vars = compute_env_vars

  # Install
  execute "#{new_resource.name}-make-install" do
    command "make install"
    cwd "#{Chef::Config[:file_cache_path]}/#{directory}"
    environment env_vars
  end
end

def action_test
  env_vars = compute_env_vars

  execute "#{new_resource.name}-make-test" do
    command "make test"
    cwd     "#{Chef::Config[:file_cache_path]}/#{directory}"
    environment env_vars
  end
end

def compute_env_vars
  env_vars = cflags

  new_resource.environment.each do |key, value|
    env_vars[key] = "" if !env_vars[key]
    env_vars[key] += " #{value}"
  end

  return env_vars
end

def directory
  new_resource.directory || new_resource.file.gsub(".tar.gz", "")
end
