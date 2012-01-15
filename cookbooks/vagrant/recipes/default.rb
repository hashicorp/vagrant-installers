env_vars = cflags.merge({
  "GEM_HOME" => "#{node[:installer][:staging_dir]}/gems",
  "GEM_PATH" => "#{node[:installer][:staging_dir]}/gems"
})

package_name = node[:vagrant][:gem_name]

execute "vagrant-gem" do
  command  "#{node[:installer][:staging_dir]}/bin/gem install #{package_name} --no-ri --no-rdoc"
  environment env_vars
end

template "#{node[:installer][:staging_dir]}/bin/vagrant" do
  mode 0755
end
