# On Linux we just compile as normal.
util_autotools "openssl" do
  file "openssl-1.0.0g.tar.gz"
  config_file "config"
  config_flags ["shared"]
  action [:compile, :test, :install]
end
