# Create the directory to hold our output
directory node[:installer][:output_dir] do
  mode 0777
end

# Build the package
execute "mac-pkg" do
  command "#{node[:installer][:packagemaker][:path]} -v -d #{node[:installer][:packagemaker][:pmdoc]} -o #{node[:installer][:output_dir]}/Vagrant.pkg"
end
