# Install FPM, which will do our actual packaging for us
include_recipe "fpm"

# Package it up!
execute "fpm-deb" do
  args = ["-p", ::File.join(node[:package][:output_dir], "vagrant_#{node[:vagrant][:version]}_#{node[:kernel][:machine]}.deb"),
          "-n", "vagrant",
          "-v", node[:vagrant][:version],
          "-s", "dir",
          "-t", "deb",
          "-C", staging_dir,
          "--prefix", node[:package][:debian][:prefix]]

  command "fpm #{args.join(" ")}"
end
