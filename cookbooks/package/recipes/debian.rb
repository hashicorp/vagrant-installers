# Install FPM, which will do our actual packaging for us
include_recipe "fpm"

# Set the output path
node[:package][:output] = ::File.join(node[:package][:output_dir],
                                      "vagrant_#{node[:vagrant][:version]}_#{node[:kernel][:machine]}.deb")

# Package it up!
execute "fpm-deb" do
  args = ["-p", node[:package][:output],
          "-n", "vagrant",
          "-v", node[:vagrant][:version],
          "-s", "dir",
          "-t", "deb",
          "-C", staging_dir,
          "--prefix", node[:package][:debian][:prefix],
          "--maintainer", "\"#{node[:package][:maintainer]}\"",
          "."]

  command "fpm #{args.join(" ")}"
  cwd     staging_dir
end
