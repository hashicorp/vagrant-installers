env_vars = {}

if platform?("mac_os_x")
  # Build a universal binary
  env_vars["CFLAGS"] = "-arch i386 -arch x86_64"
  env_vars["LDFLAGS"] = "-arch i386 -arch x86_64"

  # Set the install name to use the @rpath so this library
  # is relocatable
  env_vars["LDFLAGS"] += " -Wl,-install_name,@rpath/libreadline.dylib"
end

util_autotools "readline" do
  file "readline-6.0.tar.gz"
  environment env_vars
end
