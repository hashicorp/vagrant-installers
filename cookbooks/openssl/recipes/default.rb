util_autotools "openssl" do
  file "openssl-1.0.0g.tar.gz"
  config_file "config"
  action [:compile, :test, :install]
end
