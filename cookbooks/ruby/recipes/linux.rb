util_autotools "ruby" do
  file "ruby-1.9.3-p0.tar.gz"
  config_flags ["--disable-debug",
                "--disable-dependency-tracking",
                "--disable-install-doc",
                "--enable-shared",
                "--with-arch=x86_64,i386",
                "--with-opt-dir=#{embedded_dir}"]
end
