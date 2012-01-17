# Delete then create the directory to store our output so it is
# always empty.
directory node[:package][:output_dir] do
  recursive true
  action   :delete
end

directory node[:package][:output_dir] do
  mode      0777
  recursive true
  action    :create
end

if platform?("mac_os_x")
  include_recipe "package::mac"
elsif platform?("windows")
  include_recipe "package::windows"
else
  raise Exception, "Unsupported packaging platform: #{node[:platform]}"
end
