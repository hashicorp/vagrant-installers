env_vars = {
  "CFLAGS" => "-arch i386 -arch x86_64",
  "LDFLAGS" => "-arch i386 -arch x86_64"
}

util_autotools "libyaml" do
  file "yaml-0.1.4.tar.gz"
  config_flags ["--disable-dependency-tracking"]
  environment env_vars
end
