# TODO: Fill in the md5 sums
#
# This is the directory where we'll put all the intermediary source
# files that are needed to build a Arch binary package.
setup_dir = ::File.join(Chef::Config[:file_cache_path], "arch_setup")

vars = {
  :pkgname => "vagrant",
  :pkgver  => node[:vagrant][:version],
  :arch    => node[:kernel][:machine],
  :source  => "vagrant-#{node[:vagrant][:version]}.tar.gz"
}

directory setup_dir do
  mode 0755
  recursive true
end

# Tar up the staging directory
execute "tar-staging-dir" do
  command "tar cvzf #{vars[:source]} #{staging_dir}"
  cwd     setup_dir
end

# The PKGBUILD is used to create the binary package
template ::File.join(setup_dir, "PKGBUILD") do
  source "arch/PKGBUILD.erb"
  variables vars
end

# Make the package
execute "makepkg" do
  command "makepkg --asroot"
  cwd     setup_dir
end

