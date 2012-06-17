if platform?("mac_os_x")
  include_recipe "openssl::mac"
else
  include_recipe "openssl::linux"
end
