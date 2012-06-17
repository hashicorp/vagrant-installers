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

  # If we have a target directory, then rename the source directory
  if new_resource.target_directory
    execute "#{new_resource.name}-rename-target-directory" do
      command "mv #{source_directory} #{new_resource.target_directory}"
      cwd     Chef::Config[:file_cache_path]
    end
  end

  # Patch the thing
  if new_resource.patches && !new_resource.patches.empty?
    new_resource.patches.each do |level, files|
      level = level[1..-1]

      files.each do |file|
        util_patch "#{new_resource.name}-patch-#{file}" do
          source  file
          p_level level.to_i
          cwd     target_directory
        end
      end
    end
  end

  # Run "./configure" with the proper flags
  execute "#{new_resource.name}-configure" do
    command "./#{new_resource.config_file} #{config_flags.join(" ")}"
    cwd     target_directory
    environment env_vars
  end

  # Compile!
  execute "#{new_resource.name}-make" do
    command "make"
    cwd     target_directory
    environment env_vars
  end
end

def action_install
  env_vars = compute_env_vars

  # Install
  execute "#{new_resource.name}-make-install" do
    command "make install"
    cwd     target_directory
    environment env_vars
  end
end

def action_test
  env_vars = compute_env_vars

  execute "#{new_resource.name}-make-test" do
    command "make test"
    cwd     target_directory
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

def source_directory
  new_resource.directory || new_resource.file.gsub(".tar.gz", "")
end

def target_directory
  new_resource.target_directory || "#{Chef::Config[:file_cache_path]}/#{source_directory}"
end
