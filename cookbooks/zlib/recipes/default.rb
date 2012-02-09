env_vars = {}

if platform?("mac_os_x")
  # Build a universal binary
  env_vars["CFLAGS"] = "-arch i386 -arch x86_64"
  env_vars["LDFLAGS"] = "-arch i386 -arch x86_64"

  # Set the install name to use the @rpath so this library
  # is relocatable
  env_vars["LDFLAGS"] += " -Wl,-install_name,@rpath/libz.dylib"
end

util_autotools "zlib" do
  file "zlib-1.2.6.tar.gz"
  environment env_vars
end
