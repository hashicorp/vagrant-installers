# Build the package.
execute "mac-pkg" do
  command "#{node[:package][:packagemaker][:path]} -v -d #{node[:package][:packagemaker][:pmdoc]} -o #{node[:package][:output_dir]}/Vagrant.pkg"
end
