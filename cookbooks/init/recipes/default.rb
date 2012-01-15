# Create the directories which will store our staging environment
# that we use to package the installer.
["", "bin", "include", "gems", "lib"].each do |subdir|
  directory File.join(node[:installer][:staging_dir], subdir) do
    owner "root"
    mode  0755
    recursive true
  end
end
