config_flags = ["--disable-debug",
                "--disable-dependency-tracking"]
env_vars = {}
patches = nil

if platform?("mac_os_x")
  # Build a universal binary.
  env_vars["CFLAGS"] = "-arch i386 -arch x86_64"
  env_vars["LDFLAGS"] = "-arch i386 -arch x86_64"

  # Mac needs to setup the rpath so the lib is relocatable
  env_vars["LDFLAGS"] += " -Wl,-install_name,@rpath/libffi.dylib"

  # We have to patch libffi
  patches = { :p0 => ["mac/patch-configure.diff",
                      "mac/patch-configure-darwin11.diff"] }
end

# Compile libffi
util_autotools "libffi" do
  file "libffi-3.0.10.tar.gz"
  config_flags config_flags
  environment  env_vars
  patches      patches
end

# Move libffi headers. libffi installs its headers in a
# really strange place, so we move them into the standard
# location.
directory "#{embedded_dir}/include" do
  mode 0755
end

execute "libffi-headers-move" do
  command "mv #{embedded_dir}/lib/libffi-*/include/* #{embedded_dir}/include"
end
