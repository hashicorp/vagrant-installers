# Create the directory to hold our output
directory node[:package][:output_dir] do
  mode 0777
end

if platform?("mac_os_x")
  include_recipe "package::mac"
end
