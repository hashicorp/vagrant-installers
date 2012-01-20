# Install FPM, which will do our actual packaging for us
include_recipe "fpm"

# Package it up!
execute "fpm-deb" do
  command "fpm -n vagrant -v #{node[:vagrant][:version]} -s dir -t deb -C #{staging_dir} --prefix #{node[:package][:debian][:prefix]}"
end
