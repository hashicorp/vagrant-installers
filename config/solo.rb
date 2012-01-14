require 'pathname'
config_dir = Pathname.new(File.expand_path("../../", __FILE__))

cookbook_path config_dir.join("cookbooks").to_s
log_level :info
