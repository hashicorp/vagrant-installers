# Install FPM, which will do our actual packaging for us
include_recipe "fpm"

# Create the prefix directory, which is required by RPMs for
# some reason.
directory node[:package][:centos][:prefix] do
  mode 0755
  recursive true
end

# Package it up!
execute "fpm-rpm" do
  args = ["-p", ::File.join(node[:package][:output_dir], "vagrant_#{node[:vagrant][:version]}_#{node[:kernel][:machine]}.rpm"),
          "-n", "vagrant",
          "-v", node[:vagrant][:version],
          "-s", "dir",
          "-t", "rpm",
          "-C", staging_dir,
          "--prefix", node[:package][:centos][:prefix]]

  command "fpm #{args.join(" ")}"
end
