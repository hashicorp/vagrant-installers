if platform?("windows")
  include_recipe "ruby::windows"
else
  include_recipe "ruby::linux"
end
