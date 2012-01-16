package_name = node[:vagrant][:gem_name]

env_vars = cflags.merge({
  "GEM_HOME" => "#{embedded_dir}/gems",
  "GEM_PATH" => "#{embedded_dir}/gems"
})

# gem_package doesn't work on Mac for some reason, so we just
# directly execute the gem with the proper env vars
execute "vagrant-gem" do
  command  "#{embedded_dir}/bin/gem install #{package_name} --no-ri --no-rdoc"
  environment env_vars
end

# A linux wrapper that sets the proper GEM_HOME/GEM_PATH
# data so that it is also executed in the correct context
template "#{staging_dir}/bin/vagrant" do
  source "vagrant.erb"
  mode 0755
end
