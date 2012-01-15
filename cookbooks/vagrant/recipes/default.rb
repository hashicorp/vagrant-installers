env_vars = cflags.merge({
  "GEM_HOME" => "#{node[:isolated][:dir]}/gems",
  "GEM_PATH" => "#{node[:isolated][:dir]}/gems"
})

package_name = node[:vagrant][:gem_name]

execute "vagrant-gem" do
  command  "#{node[:isolated][:dir]}/bin/gem install #{package_name} --no-ri --no-rdoc"
  environment env_vars
end

template "#{node[:isolated][:bin_dir]}/vagrant" do
  mode 0755
end
