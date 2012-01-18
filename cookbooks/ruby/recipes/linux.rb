env_vars = {}

if platform?("mac_os_x")
  # Mac needs to setup the rpath for the libraries
  env_vars["LDFLAGS"] = "-Wl,-rpath,@loader_path/../lib -Wl,-rpath,@executable_path/../lib"
end

util_autotools "ruby" do
  file "ruby-1.9.3-p0.tar.gz"
  config_flags ["--disable-debug",
                "--disable-dependency-tracking",
                "--disable-install-doc",
                "--enable-shared",
                "--with-arch=x86_64,i386",
                "--with-opt-dir=#{embedded_dir}",
                "--enable-load-relative"]
  environment env_vars
end
