config_flags = ["--disable-debug",
                "--disable-dependency-tracking",
                "--disable-install-doc",
                "--enable-shared",
                "--with-opt-dir=#{embedded_dir}",
                "--enable-load-relative"]
env_vars = {}

if platform?("mac_os_x")
  # Mac needs to setup the rpath for the libraries
  env_vars["LDFLAGS"] = "-Wl,-rpath,@loader_path/../lib -Wl,-rpath,@executable_path/../lib"

  # Build a Mach Universal Binary on Mac
  config_flags << "--with-arch=x86_64,i386"
elsif node[:os] == "linux"
  # On all linux installations, add in this rpath so that our
  # libraries can be accessed when called from the `ruby`
  # binary.
  env_vars["LDFLAGS"] = "-Wl,-rpath,$ORIGIN/../lib"
end

util_autotools "ruby" do
  file "ruby-1.9.3-p0.tar.gz"
  config_flags config_flags
  environment env_vars
end
