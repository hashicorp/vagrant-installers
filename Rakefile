task :default => :build

task :build do
  exec("sudo -E chef-solo -c config/solo.rb -j config/solo.json")
end
