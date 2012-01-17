include_recipe "7-zip"

# Download Ruby 7zip Archive (Thanks to RubyInstaller!)
file_cache_path = ::File.expand_path(Chef::Config[:file_cache_path])
file_cache_path = file_cache_path.gsub("/", "\\")
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
  xcopy #{unzip_directory} \"#{node[:installer][:staging_dir]}\" /e /y
  EOH
end
