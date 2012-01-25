# Make sure the file cache exists. We do this during the compilation
# phase since the git checkout (which also happens during the compilation
# phase) depends on this.
directory Chef::Config[:file_cache_path] do
  mode 0755
  recursive true
  action :nothing
end.run_action(:create)

# Create the directories which will store our staging environment
# that we use to package the installer.
["", "bin", "embedded"].each do |subdir|
  directory ::File.join(node[:installer][:staging_dir], subdir) do
    mode  0755
    recursive true
  end
end
