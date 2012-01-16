if platform?("windows")
  include_recipe "vagrant::windows"
else
  include_recipe "vagrant::linux"
end
