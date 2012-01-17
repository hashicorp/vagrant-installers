download_path = ::File.join(Chef::Config[:file_cache_path], "wix.zip")

cookbook_file download_path do
  source "wix.zip"
end

windows_zipfile "wix" do
  path node[:wix][:home]
  source download_path
  not_if do
    ::File.exists?(::File.join(node[:wix][:home], "heat.exe"))
  end
end

windows_path node[:wix][:home] do
  action :add
end
