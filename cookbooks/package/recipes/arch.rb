# TODO: Fill in the md5 sums
#
# This is the directory where we'll put all the intermediary source
# files that are needed to build a Arch binary package.
setup_dir = ::File.join(Chef::Config[:file_cache_path], "arch_setup")
source_name = "#{vars[:pkgname]}-#{vars[:pkgver]}.tar.gz"

directory setup_dir do
  mode 0755
  recursive true
end

# Tar up the staging directory
execute "tar-staging-dir" do
  command "tar cvzf #{source_name} #{staging_dir}"
  pwd     setup_dir
end

# The PKGBUILD is used to create the binary package
vars = {
  :pkgname => "vagrant",
  :pkgver  => node[:vagrant][:version],
  :arch    => node[:kernel][:machine],
  :source  => source_name
}

template ::File.join(setup_dir, "PKGBUILD") do
  source "PKGBUILD.erb"
  variables vars
end
=begin
# Make the package
execute "makepkg" do
  command "makepkg --asroot"
  cwd     setup_dir
end

# TODO: Read the pkg.tar.gz file and copy into the dist dir
=end
