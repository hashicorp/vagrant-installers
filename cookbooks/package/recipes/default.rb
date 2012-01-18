# Delete then create the directory to store our output so it is
# always empty.
if ::File.directory?(node[:package][:output_dir])
  directory node[:package][:output_dir] do
    recursive true
    action   :delete
  end

  # For some reason Windows has some issues with
  # race conditions of deleting a folder then really
  # quickly recreating it. Just sleep.
  ruby_block "sleep-delay" do
    block do
      sleep 1
    end
  end
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
