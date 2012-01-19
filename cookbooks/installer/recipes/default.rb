include_recipe "init"

if platform?("mac_os_x")
  include_recipe "installer::mac"
elsif platform?("windows")
  include_recipe "installer::windows"
elsif platform?("ubuntu")
  include_recipe "installer::ubuntu"
else
  raise "Unsupported platform: #{node[:platform]}"
end
