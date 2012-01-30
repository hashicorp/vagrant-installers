# Install FPM, which will do our actual packaging for us
include_recipe "fpm"

# Set the output name
node[:package][:output] = ::File.join(node[:package][:output_dir],
                                      "vagrant_#{node[:vagrant][:version]}_#{node[:kernel][:machine]}.rpm")

# Create the prefix directory, which is required by RPMs for
# some reason.
directory node[:package][:centos][:prefix] do
  mode 0755
  recursive true
end

# Package it up!
execute "fpm-rpm" do
  args = ["-p", node[:package][:output],
          "-n", "vagrant",
          "-v", node[:vagrant][:version],
          "-s", "dir",
          "-t", "rpm",
          "-C", staging_dir,
          "--prefix", node[:package][:centos][:prefix]]

  command "fpm #{args.join(" ")}"
end
