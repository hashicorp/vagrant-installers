env_vars = {}

if platform?("mac_os_x")
  # Build a universal binary
  env_vars["CFLAGS"] = "-arch i386 -arch x86_64"
  env_vars["LDFLAGS"] = "-arch i386 -arch x86_64"

  # Set the install name to use the @rpath so this library
  # is relocatable
  env_vars["LDFLAGS"] += " -Wl,-install_name,@rpath/libyaml.dylib"
end

util_autotools "openssl" do
  file "openssl-1.0.0g.tar.gz"
  config_file "config"
  config_flags ["shared"]
  environment  env_vars
  action [:compile, :test, :install]
end
