require 'pathname'
require 'tmpdir'
root_dir = Pathname.new(File.expand_path("../../", __FILE__))

cookbook_path root_dir.join("cookbooks").to_s
file_cache_path root_dir.join("chef-cache").to_s
log_level :info
