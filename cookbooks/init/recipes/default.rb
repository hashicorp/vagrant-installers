# Make sure the file cache exists.
directory Chef::Config[:file_cache_path] do
  mode 0755
  recursive true
end

# Create the directories which will store our staging environment
# that we use to package the installer.
["", "bin", "embedded"].each do |subdir|
  directory ::File.join(node[:installer][:staging_dir], subdir) do
    mode  0755
    recursive true
  end
end
