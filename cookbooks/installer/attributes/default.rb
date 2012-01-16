case platform
when 'windows'
  default[:installer][:staging_dir] = "#{ENV['SYSTEMDRIVE']}\\vagrant-temp"
else
  default[:installer][:staging_dir] = "/tmp/vagrant-temp"
end
