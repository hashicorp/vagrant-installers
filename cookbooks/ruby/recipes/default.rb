env_vars = {
  "LDFLAGS" => "-R#{node[:isolated][:lib_dir]} -L#{node[:isolated][:lib_dir]} -I#{node[:isolated][:include_dir]}",
  "CLFAGS"  => "-I#{node[:isolated][:include_dir]} -L#{node[:isolated][:lib_dir]}"
}

# Upload the blessed version of ruby into the file cache.
cookbook_file "#{Chef::Config[:file_cache_path]}/ruby.tar.gz" do
  source "ruby-1.9.3-p0.tar.gz"
end

# Untar and compile with the proper flags.
execute "ruby-untar" do
  command "tar xvzf ruby.tar.gz"
  cwd Chef::Config[:file_cache_path]
end

execute "ruby-configure" do
  command "./configure --prefix=#{node[:isolated][:dir]} --disable-debug --disable-dependency-tracking --disable-install-doc --enable-shared --with-arch=x86_64,i386"
  cwd "#{Chef::Config[:file_cache_path]}/ruby-1.9.3-p0"
  environment env_vars
end

execute "ruby-make" do
  command "make"
  cwd "#{Chef::Config[:file_cache_path]}/ruby-1.9.3-p0"
  environment env_vars
end

execute "ruby-make-install" do
  command "make install"
  cwd "#{Chef::Config[:file_cache_path]}/ruby-1.9.3-p0"
  environment env_vars
end
