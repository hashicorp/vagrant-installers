env_vars = {}

if platform?("mac_os_x")
  # Build a universal binary
  env_vars["CFLAGS"] = "-arch i386 -arch x86_64"
  env_vars["LDFLAGS"] = "-arch i386 -arch x86_64"

  # Set the install name to use the @rpath so this library
  # is relocatable
  env_vars["LDFLAGS"] += " -Wl,-install_name,@rpath/libyaml.dylib"
end

util_autotools "libyaml" do
  file "yaml-0.1.4.tar.gz"
  config_flags ["--disable-dependency-tracking"]
  environment env_vars
end
