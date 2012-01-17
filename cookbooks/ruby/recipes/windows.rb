include_recipe "7-zip"

# The directory where we will expand Ruby
expand_dir = node[:installer][:staging_dir]

# Get the file cache path with Windows-style paths
file_cache_path = ::File.expand_path(Chef::Config[:file_cache_path])
file_cache_path = file_cache_path.gsub("/", "\\")

#----------------------------------------------------------------------
# Ruby
#----------------------------------------------------------------------
# Download Ruby 7zip Archive (Thanks to RubyInstaller!)
ruby_filename = ::File.basename(node[:ruby][:win_url])
ruby_download_path = ::File.join(file_cache_path, ruby_filename)

remote_file ruby_download_path do
  source   node[:ruby][:win_url]
  checksum node[:ruby][:win_checksum]
end

# Unzip the archive and move it to the embedded directory
unzip_directory = ::File.basename(ruby_filename, ".7z")
unzip_directory = "#{file_cache_path}\\#{unzip_directory}"
windows_batch "unzip-ruby" do
  code <<-EOH
  "#{node[:sevenzip][:home]}\\7z.exe" x #{ruby_download_path} -o#{Chef::Config[:file_cache_path]} -r -y
  xcopy #{unzip_directory} \"#{expand_dir}\" /e /y
  EOH

  not_if do
    ::File.exists?("#{expand_dir}/bin/ruby.exe")
  end
end

#----------------------------------------------------------------------
# DevKit
#----------------------------------------------------------------------
# Download the DevKit
devkit_filename = ::File.basename(node[:ruby][:win_devkit_url])
devkit_download_path = ::File.join(file_cache_path, devkit_filename)

remote_file devkit_download_path do
  source   node[:ruby][:win_devkit_url]
  checksum node[:ruby][:win_devkit_checksum]
end

template "#{expand_dir}/config.yml" do
  source "config.yml.erb"
  variables :ruby_path => expand_dir
end

windows_batch "install-devkit-and-enhance-ruby" do
  code <<-EOH
  #{devkit_download_path} -y -o\"#{expand_dir}\"
  cd \"#{expand_dir}\" & \"#{expand_dir}\\bin\\ruby.exe\" \"#{expand_dir}\\dk.rb\" install
  EOH

  not_if do
    ::File.exists?("#{expand_dir}/dk.rb")
  end
end
