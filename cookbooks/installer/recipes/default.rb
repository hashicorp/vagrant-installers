include_recipe "init"

if platform?("mac_os_x")
  include_recipe "installer::mac"
else
  raise Exception, "Unsupported platform: #{node[:platform]}"
end
