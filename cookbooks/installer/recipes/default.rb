include_recipe "init"

if platform?("mac_os_x")
  include_recipe "installer::mac"
else
  include_recipe "installer::windows"
end
