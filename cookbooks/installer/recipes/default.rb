include_recipe "init"

if platform?("mac_os_x")
  include_recipe "installer::mac"
elsif platform?("windows")
  include_recipe "installer::windows"
elsif platform?("ubuntu")
  include_recipe "installer::ubuntu"
elsif platform?("centos")
  include_recipe "installer::centos"
elsif platform?("arch")
  include_recipe "installer::arch"
else
  raise "Unsupported platform: #{node[:platform]}"
end
